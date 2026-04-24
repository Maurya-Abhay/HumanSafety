// Police Dispatch Service - Broadcasts to nearby officers with lock mechanism
// Ensures only ONE police can accept each case

const User = require('../models/user.model');
const Emergency = require('../models/emergency.model');
const { sendSMS } = require('./sms.service');

const EARTH_RADIUS = 6371; // km
const DISPATCH_RADIUS = 5; // km (broadcast to all within 5km)
const ACCEPTANCE_LOCK_TIMEOUT = 30 * 1000; // 30 seconds to accept

class PoliceDispatchService {
  // ============================================================
  // DISTANCE CALCULATION
  // ============================================================

  static calculateDistance(lat1, lon1, lat2, lon2) {
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) *
        Math.cos(this.toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return EARTH_RADIUS * c;
  }

  static toRad(deg) {
    return deg * (Math.PI / 180);
  }

  // ============================================================
  // FIND NEARBY POLICE OFFICERS
  // ============================================================

  /**
   * Find nearby police officers sorted by distance
   */
  static async findNearbyPoliceOfficers(latitude, longitude, radiusKm = DISPATCH_RADIUS) {
    try {
      const officers = await User.find({
        role: 'police',
        status: 'active',
        isBlocked: false,
      }).select('name phone currentLocation');

      // Calculate distance for each officer
      const nearbyOfficers = officers
        .map(officer => {
          let distance = Infinity;
          if (officer.currentLocation?.latitude && officer.currentLocation?.longitude) {
            distance = this.calculateDistance(
              latitude,
              longitude,
              officer.currentLocation.latitude,
              officer.currentLocation.longitude
            );
          }
          return {
            ...officer.toObject(),
            distance,
          };
        })
        .filter(o => o.distance <= radiusKm)
        .sort((a, b) => a.distance - b.distance);

      console.log(`👮 Found ${nearbyOfficers.length} officers within ${radiusKm}km`);
      return nearbyOfficers;
    } catch (error) {
      console.error('Failed to find nearby officers:', error.message);
      throw error;
    }
  }

  // ============================================================
  // BROADCAST EMERGENCY
  // ============================================================

  /**
   * Broadcast emergency to nearby police officers
   * RULE: First to accept gets the case (lock mechanism)
   */
  static async broadcastEmergency(emergencyId, userLocation) {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      console.log(
        `📢 Broadcasting emergency ${emergencyId} to nearby police...\n` +
        `Location: ${userLocation.latitude}, ${userLocation.longitude}`
      );

      // Step 1: Find nearby police
      const nearbyOfficers = await this.findNearbyPoliceOfficers(
        userLocation.latitude,
        userLocation.longitude
      );

      if (nearbyOfficers.length === 0) {
        throw new Error('No police officers found within broadcast radius');
      }

      // Step 2: Update emergency state
      emergency.state = 'BROADCASTED';
      emergency.broadcastedAt = new Date();
      emergency.policeRoutingLog = nearbyOfficers.map(officer => ({
        policeId: officer._id,
        sentAt: new Date(),
        status: 'SENT',
      }));
      await emergency.save();

      // Step 3: Send notifications concurrently to all nearby officers
      const notifications = nearbyOfficers.map(officer =>
        this.sendDispatchNotification(emergencyId, officer, userLocation)
      );

      await Promise.allSettled(notifications);

      console.log(`✅ Broadcast sent to ${nearbyOfficers.length} officers`);
      console.log(`⏰ Officers have ${ACCEPTANCE_LOCK_TIMEOUT / 1000} seconds to accept`);

      return {
        emergencyId,
        broadcastedAt: new Date(),
        targetOfficers: nearbyOfficers.length,
        officers: nearbyOfficers.map(o => ({
          id: o._id,
          name: o.name,
          distance: o.distance,
        })),
      };
    } catch (error) {
      console.error('Failed to broadcast emergency:', error.message);
      throw error;
    }
  }

  /**
   * Send dispatch notification to individual officer
   */
  static async sendDispatchNotification(emergencyId, officer, userLocation) {
    try {
      const message =
        `🚨 NEW EMERGENCY DISPATCH\n` +
        `Type: ACCIDENT/EMERGENCY\n` +
        `Location: ${userLocation.address || `${userLocation.latitude.toFixed(2)}, ${userLocation.longitude.toFixed(2)}`}\n` +
        `Distance: ~${officer.distance?.toFixed(1)}km\n` +
        `🔴 ACCEPT: Reply 'ACCEPT' to lock case | You have 30 seconds`;

      await sendSMS(officer.phone, message);

      console.log(`📱 Notification sent to ${officer.name} (${officer.distance?.toFixed(1)}km)`);
    } catch (error) {
      console.error(`Failed to send notification to ${officer.name}:`, error.message);
    }
  }

  // ============================================================
  // ACCEPTANCE LOCK MECHANISM
  // ============================================================

  /**
   * Police officer accepts case with ATOMIC LOCK
   * CRITICAL: Ensure only ONE officer can accept
   * Uses MongoDB atomic operations to prevent race conditions
   */
  static async acceptEmergencyWithLock(emergencyId, policeId) {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      // ATOMIC CHECK: Has another officer already accepted?
      if (emergency.assignedPolice && 
          emergency.assignedPolice.toString() !== policeId.toString()) {
        console.warn(
          `⚠️  Police ${policeId} tried to accept, but ${emergency.assignedPolice} already accepted`
        );
        return {
          success: false,
          reason: 'ALREADY_ACCEPTED_BY_ANOTHER_OFFICER',
          assignedToPolice: emergency.assignedPolice,
        };
      }

      // ATOMIC UPDATE: Only update if assignedPolice is null
      const updatedEmergency = await Emergency.findByIdAndUpdate(
        emergencyId,
        {
          $set: {
            assignedPolice: policeId,
            state: 'ACCEPTED',
            policeAcceptedAt: new Date(),
            acceptedAt: new Date(),
            policeStatus: 'ACCEPTED',
            firstResponseAt: new Date(),
          },
        },
        {
          new: true,
          // Conditional update only if assignedPolice was null
          upsert: false,
        }
      );

      if (!updatedEmergency.assignedPolice.equals(policeId)) {
        throw new Error('Lock acquisition failed - another officer accepted first');
      }

      // Update routing log
      const routeIndex = updatedEmergency.policeRoutingLog.findIndex(
        r => r.policeId.toString() === policeId.toString()
      );
      if (routeIndex !== -1) {
        updatedEmergency.policeRoutingLog[routeIndex].respondedAt = new Date();
        updatedEmergency.policeRoutingLog[routeIndex].status = 'ACCEPTED';
        await updatedEmergency.save();
      }

      console.log(`✅ Police ${policeId} ACCEPTED emergency ${emergencyId} (LOCKED)`);

      // Cancel for all other officers
      const otherOfficers = updatedEmergency.policeRoutingLog.filter(
        r => r.status === 'SENT'
      );
      await this.cancelDispatchForOthers(emergencyId, policeId, otherOfficers);

      return {
        success: true,
        emergencyId,
        policeId,
        state: 'ACCEPTED',
        acceptedAt: new Date(),
      };
    } catch (error) {
      console.error('Failed to accept emergency with lock:', error.message);
      throw error;
    }
  }

  /**
   * Cancel dispatch for all other officers (case already taken)
   */
  static async cancelDispatchForOthers(emergencyId, acceptedByPoliceId, otherOfficers) {
    try {
      const cancelMessages = otherOfficers.map(async route => {
        const officer = await User.findById(route.policeId);
        if (!officer || officer._id.toString() === acceptedByPoliceId.toString()) {
          return;
        }

        const message = `✅ Case was accepted by another officer. Case #${emergencyId} is now closed for you.`;
        await sendSMS(officer.phone, message);
      });

      await Promise.allSettled(cancelMessages);
      console.log(`📵 Cancel notifications sent to other officers`);
    } catch (error) {
      console.error('Failed to send cancel notifications:', error.message);
    }
  }

  /**
   * Police officer rejects case
   */
  static async rejectEmergency(emergencyId, policeId, reason = '') {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      if (emergency.assignedPolice?.toString() === policeId.toString()) {
        // Officer who accepted is rejecting
        emergency.assignedPolice = null;
        emergency.state = 'BROADCASTED'; // Back to broadcast state
        emergency.policeStatus = null;
      }

      // Mark in routing log
      const routeIndex = emergency.policeRoutingLog.findIndex(
        r => r.policeId.toString() === policeId.toString()
      );
      if (routeIndex !== -1) {
        emergency.policeRoutingLog[routeIndex].respondedAt = new Date();
        emergency.policeRoutingLog[routeIndex].status = 'REJECTED';
      }

      await emergency.save();

      console.log(`❌ Police ${policeId} rejected emergency ${emergencyId}`);
      console.log(`Reason: ${reason || 'Not specified'}`);

      return emergency;
    } catch (error) {
      console.error('Failed to reject emergency:', error.message);
      throw error;
    }
  }

  // ============================================================
  // STATUS UPDATES
  // ============================================================

  /**
   * Police updates case status with location
   */
  static async updateCaseStatus(emergencyId, policeId, status, location) {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      // Verify this police is assigned
      if (emergency.assignedPolice?.toString() !== policeId.toString()) {
        throw new Error('This case is not assigned to you');
      }

      // Update status
      emergency.policeStatus = status; // ACCEPTED, ON_THE_WAY, ARRIVED, PROVIDING_HELP, RESOLVED
      emergency.policeCurrentLocation = {
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: new Date(),
      };

      // Add to location history
      emergency.locationHistory.push({
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: new Date(),
        source: 'POLICE',
      });

      await emergency.save();

      console.log(`📍 Police ${policeId} status update: ${status}`);

      return emergency;
    } catch (error) {
      console.error('Failed to update case status:', error.message);
      throw error;
    }
  }

  /**
   * Police resolves case
   */
  static async resolveCase(emergencyId, policeId, resolutionDetails = '') {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      // Verify authorization
      if (emergency.assignedPolice?.toString() !== policeId.toString() && 
          emergency.assignedHospital?.toString() !== policeId.toString()) {
        throw new Error('Not authorized to resolve this case');
      }

      // Update resolution
      emergency.state = 'RESOLVED';
      emergency.policeStatus = 'RESOLVED';
      emergency.resolvedAt = new Date();
      emergency.resolution = resolutionDetails;

      // Calculate response time
      if (emergency.acceptedAt) {
        emergency.totalResolutionTime = emergency.resolvedAt - emergency.acceptedAt;
      }

      if (emergency.firstResponseAt) {
        emergency.timeToFirstResponse = emergency.firstResponseAt - emergency.createdAt;
      }

      await emergency.save();

      console.log(
        `✅ Emergency ${emergencyId} RESOLVED\n` +
        `Response time: ${emergency.totalResolutionTime / 1000} seconds\n` +
        `Details: ${resolutionDetails}`
      );

      return emergency;
    } catch (error) {
      console.error('Failed to resolve case:', error.message);
      throw error;
    }
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  /**
   * Get police dispatch analytics
   */
  static async getDispatchAnalytics(timeWindowDays = 30) {
    try {
      const startDate = new Date(Date.now() - timeWindowDays * 24 * 60 * 60 * 1000);

      const emergencies = await Emergency.find({
        createdAt: { $gte: startDate },
        assignedPolice: { $ne: null },
      });

      const totalDispatched = emergencies.length;
      const avgResponseTime =
        emergencies.reduce((sum, e) => sum + (e.timeToFirstResponse || 0), 0) /
        totalDispatched;
      const avgResolutionTime =
        emergencies.reduce((sum, e) => sum + (e.totalResolutionTime || 0), 0) /
        totalDispatched;

      return {
        timeWindowDays,
        totalEmergenciesDispatched: totalDispatched,
        avgResponseTimeMs: avgResponseTime,
        avgResolutionTimeMs: avgResolutionTime,
        resolvedCases: emergencies.filter(e => e.state === 'RESOLVED').length,
        escalatedCases: emergencies.filter(e => e.state === 'ESCALATED').length,
      };
    } catch (error) {
      console.error('Failed to get analytics:', error.message);
      throw error;
    }
  }
}

module.exports = PoliceDispatchService;
