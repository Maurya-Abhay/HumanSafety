// Hospital Routing Service - Intelligent routing with 10-second response window
// Ensures patient gets routed to nearest available hospital

const User = require('../models/user.model');
const Emergency = require('../models/emergency.model');
const { sendSMS } = require('./sms.service');

const HOSPITAL_RESPONSE_TIMEOUT = 10 * 1000; // 10 seconds
const EARTH_RADIUS = 6371; // km

class HospitalRoutingService {
  // ============================================================
  // HAVERSINE DISTANCE CALCULATION
  // ============================================================

  /**
   * Calculate distance between two coordinates (in km)
   */
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
  // FIND NEAREST HOSPITALS
  // ============================================================

  /**
   * Find nearby hospitals sorted by distance
   */
  static async findNearbyHospitals(latitude, longitude, radiusKm = 15) {
    try {
      const hospitals = await User.find({
        role: 'hospital',
        status: 'active',
        isBlocked: false,
      }).select('name phone hospitalDetails');

      // Calculate distance for each hospital
      const nearbyHospitals = hospitals
        .map(hospital => {
          const distance = this.calculateDistance(
            latitude,
            longitude,
            hospital.hospitalDetails.location.latitude,
            hospital.hospitalDetails.location.longitude
          );
          return {
            ...hospital.toObject(),
            distance,
          };
        })
        .filter(h => h.distance <= radiusKm)
        .sort((a, b) => a.distance - b.distance);

      console.log(`🏥 Found ${nearbyHospitals.length} hospitals within ${radiusKm}km`);
      return nearbyHospitals;
    } catch (error) {
      console.error('Failed to find nearby hospitals:', error.message);
      throw error;
    }
  }

  // ============================================================
  // INTELLIGENT HOSPITAL ROUTING
  // ============================================================

  /**
   * Route emergency to hospitals with intelligent retry logic
   * RULE: Wait 10 seconds for response, then move to next hospital
   */
  static async routeEmergency(emergencyId, userLocation, specializations = []) {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      console.log(
        `🚑 Routing emergency ${emergencyId} to nearest hospitals...\n` +
        `Location: ${userLocation.latitude}, ${userLocation.longitude}`
      );

      // Step 1: Find nearby hospitals
      const nearbyHospitals = await this.findNearbyHospitals(
        userLocation.latitude,
        userLocation.longitude
      );

      if (nearbyHospitals.length === 0) {
        throw new Error('No hospitals found within 15km radius');
      }

      // Step 2: Filter by specialization if specified
      let targetHospitals = nearbyHospitals;
      if (specializations.length > 0) {
        targetHospitals = nearbyHospitals.filter(h =>
          specializations.some(spec =>
            h.hospitalDetails.specializations?.includes(spec)
          )
        );
      }

      if (targetHospitals.length === 0) {
        // Fallback to all nearby hospitals if specialization not found
        targetHospitals = nearbyHospitals;
      }

      // Step 3: Sequential routing with 10-second timeout
      for (let i = 0; i < targetHospitals.length; i++) {
        const hospital = targetHospitals[i];

        console.log(
          `📧 Attempt ${i + 1}/${targetHospitals.length}: Sending to ${hospital.hospitalDetails.hospitalName} ` +
          `(${hospital.distance.toFixed(1)}km away)`
        );

        // Send routing request
        const result = await this.sendRoutingRequest(
          emergencyId,
          hospital._id,
          userLocation,
          i
        );

        // Wait for response with timeout
        const accepted = await this.waitForHospitalResponse(
          emergencyId,
          hospital._id,
          HOSPITAL_RESPONSE_TIMEOUT
        );

        if (accepted) {
          console.log(`✅ Hospital ${hospital.hospitalDetails.hospitalName} ACCEPTED`);
          return {
            success: true,
            hospitalId: hospital._id,
            hospitalName: hospital.hospitalDetails.hospitalName,
            distance: hospital.distance,
            attempt: i + 1,
          };
        }

        console.log(
          `⏱️  Hospital ${hospital.hospitalDetails.hospitalName} didn't respond in 10 sec. ` +
          `Trying next...`
        );
      }

      // Step 4: All hospitals rejected/timed out
      console.error(
        `❌ All ${targetHospitals.length} hospitals rejected or timed out. ` +
        `Escalating...`
      );

      await Emergency.findByIdAndUpdate(emergencyId, {
        state: 'ESCALATED',
        escalationReason: 'NO_HOSPITAL_ACCEPTED',
        escalationCount: emergency.escalationCount + 1,
      });

      throw new Error('No hospital accepted the emergency request');
    } catch (error) {
      console.error('Emergency routing failed:', error.message);
      throw error;
    }
  }

  /**
   * Send routing request to hospital
   */
  static async sendRoutingRequest(emergencyId, hospitalId, userLocation, attemptNumber) {
    try {
      const emergency = await Emergency.findById(emergencyId);
      const hospital = await User.findById(hospitalId);

      if (!emergency || !hospital) {
        throw new Error('Emergency or Hospital not found');
      }

      // Add to routing log
      emergency.hospitalRoutingLog.push({
        hospitalId,
        sentAt: new Date(),
        status: 'SENT',
      });
      await emergency.save();

      // Send SMS notification to hospital
      const message =
        `🚨 EMERGENCY REQUEST #${attemptNumber + 1}\n` +
        `Type: ${emergency.type}\n` +
        `Location: ${emergency.location.address}\n` +
        `Distance: ~${emergency.location.distance?.toFixed(1)}km\n` +
        `Available Beds: ${hospital.hospitalDetails.availableBeds}\n` +
        `Accept: Reply 'ACCEPT' | Reject: Reply 'REJECT'`;

      await sendSMS(hospital.phone, message);

      console.log(`📱 SMS sent to ${hospital.hospitalDetails.hospitalName}`);

      return {
        sentAt: new Date(),
        hospitalId,
      };
    } catch (error) {
      console.error('Failed to send routing request:', error.message);
      throw error;
    }
  }

  /**
   * Wait for hospital response (with timeout)
   * In production, this would use WebSocket or polling
   */
  static async waitForHospitalResponse(emergencyId, hospitalId, timeoutMs) {
    return new Promise((resolve, reject) => {
      const startTime = Date.now();
      const pollInterval = 500; // Poll every 500ms

      const poll = async () => {
        try {
          const emergency = await Emergency.findById(emergencyId);

          if (!emergency) {
            resolve(false);
            return;
          }

          // Check if hospital accepted
          if (emergency.assignedHospital?.toString() === hospitalId.toString() &&
              emergency.state === 'ACCEPTED') {
            resolve(true);
            return;
          }

          // Check timeout
          const elapsed = Date.now() - startTime;
          if (elapsed >= timeoutMs) {
            resolve(false);
            return;
          }

          // Continue polling
          setTimeout(poll, pollInterval);
        } catch (error) {
          resolve(false);
        }
      };

      poll();
    });
  }

  // ============================================================
  // HOSPITAL RESPONSE HANDLERS
  // ============================================================

  /**
   * Hospital accepts emergency
   */
  static async acceptEmergency(hospitalId, emergencyId) {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      // Mark hospital as accepted
      emergency.assignedHospital = hospitalId;
      emergency.state = 'ACCEPTED';
      emergency.hospitalAcceptedAt = new Date();
      emergency.hospitalResponseTime =
        Date.now() - emergency.hospitalRoutingLog[0]?.sentAt;
      emergency.acceptedAt = new Date();

      // Update routing log
      const routeIndex = emergency.hospitalRoutingLog.findIndex(
        r => r.hospitalId.toString() === hospitalId.toString()
      );
      if (routeIndex !== -1) {
        emergency.hospitalRoutingLog[routeIndex].respondedAt = new Date();
        emergency.hospitalRoutingLog[routeIndex].status = 'ACCEPTED';
        emergency.hospitalRoutingLog[routeIndex].responseTime = emergency.hospitalResponseTime;
      }

      await emergency.save();

      console.log(`✅ Hospital ${hospitalId} accepted emergency ${emergencyId}`);
      return emergency;
    } catch (error) {
      console.error('Failed to accept emergency:', error.message);
      throw error;
    }
  }

  /**
   * Hospital rejects emergency
   */
  static async rejectEmergency(hospitalId, emergencyId, reason = '') {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency) {
        throw new Error('Emergency not found');
      }

      // Mark as rejected in routing log
      const routeIndex = emergency.hospitalRoutingLog.findIndex(
        r => r.hospitalId.toString() === hospitalId.toString()
      );
      if (routeIndex !== -1) {
        emergency.hospitalRoutingLog[routeIndex].respondedAt = new Date();
        emergency.hospitalRoutingLog[routeIndex].status = 'REJECTED';
      }

      await emergency.save();

      console.log(`❌ Hospital ${hospitalId} rejected emergency ${emergencyId}`);
      console.log(`Reason: ${reason || 'Not specified'}`);

      // Auto-route to next hospital
      return await this.routeEmergency(
        emergencyId,
        emergency.location,
        emergency.specializations
      );
    } catch (error) {
      console.error('Failed to reject emergency:', error.message);
      throw error;
    }
  }

  // ============================================================
  // HOSPITAL CAPACITY MANAGEMENT
  // ============================================================

  /**
   * Check and validate hospital bed availability
   */
  static async validateHospitalCapacity(hospitalId) {
    try {
      const hospital = await User.findById(hospitalId);

      if (!hospital) {
        throw new Error('Hospital not found');
      }

      const { availableBeds, totalBeds } = hospital.hospitalDetails;
      const occupancyRate = ((totalBeds - availableBeds) / totalBeds) * 100;

      return {
        hospitalId,
        availableBeds,
        totalBeds,
        occupancyRate,
        canAccept: availableBeds > 0,
      };
    } catch (error) {
      console.error('Failed to validate capacity:', error.message);
      throw error;
    }
  }

  /**
   * Update bed availability after patient admission
   */
  static async updateBedAvailability(hospitalId, bedsUsed = 1) {
    try {
      const hospital = await User.findById(hospitalId);

      if (!hospital) {
        throw new Error('Hospital not found');
      }

      hospital.hospitalDetails.availableBeds = Math.max(
        0,
        hospital.hospitalDetails.availableBeds - bedsUsed
      );
      await hospital.save();

      console.log(
        `🛏️  Hospital ${hospitalId}: ${hospital.hospitalDetails.availableBeds} beds available`
      );
      return hospital.hospitalDetails;
    } catch (error) {
      console.error('Failed to update bed availability:', error.message);
      throw error;
    }
  }

  // ============================================================
  // ANALYTICS
  // ============================================================

  /**
   * Get hospital routing analytics
   */
  static async getRoutingAnalytics(timeWindowDays = 30) {
    try {
      const startDate = new Date(Date.now() - timeWindowDays * 24 * 60 * 60 * 1000);

      const emergencies = await Emergency.find({
        createdAt: { $gte: startDate },
        assignedHospital: { $ne: null },
      });

      const totalRouted = emergencies.length;
      const avgResponseTime =
        emergencies.reduce((sum, e) => sum + (e.hospitalResponseTime || 0), 0) /
        totalRouted;
      const avgDistance =
        emergencies.reduce((sum, e) => sum + (e.distance || 0), 0) / totalRouted;

      const acceptanceRates = {};
      emergencies.forEach(e => {
        e.hospitalRoutingLog.forEach(route => {
          if (!acceptanceRates[route.status]) {
            acceptanceRates[route.status] = 0;
          }
          acceptanceRates[route.status]++;
        });
      });

      return {
        timeWindowDays,
        totalEmergenciesRouted: totalRouted,
        avgResponseTimeMs: avgResponseTime,
        avgDistanceKm: avgDistance,
        acceptanceRates,
      };
    } catch (error) {
      console.error('Failed to get analytics:', error.message);
      throw error;
    }
  }
}

module.exports = HospitalRoutingService;
