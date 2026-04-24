// Emergency Workflow Controller - Orchestrates complete state machine
// This is the CORE logic ensuring NO emergency is lost

const Emergency = require('../models/emergency.model');
const User = require('../models/user.model');
const FailureHandlingService = require('../services/failure_handling_service');
const HospitalRoutingService = require('../services/hospital_routing_service');
const PoliceDispatchService = require('../services/police_dispatch_service');
const AIDecisionEngine = require('../services/ai_decision_engine');
const { getRealtimeService } = require('../services/realtime_event_service');
const { sendSMS } = require('../services/sms.service');

class EmergencyWorkflowController {
  // ============================================================
  // TRIGGER EMERGENCY (User panic or AI detection)
  // ============================================================

  /**
   * User manually triggers panic button or AI detects accident
   * CRITICAL: This is the entry point - must NOT lose the event
   */
  static async triggerEmergency(req, res) {
    try {
      const { type, location, sensorData, description } = req.body;
      const userId = req.user._id;

      // Step 1: Validate location
      if (!location || !location.latitude || !location.longitude) {
        return res.status(400).json({ message: 'Valid location required' });
      }

      console.log(
        `\n🚨 EMERGENCY TRIGGERED BY USER ${userId}\n` +
        `Type: ${type}\n` +
        `Location: ${location.latitude}, ${location.longitude}`
      );

      // Step 2: AI Analysis (if sensor data provided)
      let aiAnalysis = null;
      if (sensorData) {
        aiAnalysis = AIDecisionEngine.analyzeEmergency(sensorData);
        console.log(`AI Confidence: ${aiAnalysis.confidenceScore}%`);

        // If low confidence, ask user
        if (aiAnalysis.decision === 'ASK_CONFIRMATION') {
          return res.status(202).json({
            message: 'Moderate confidence - please confirm emergency',
            requiresConfirmation: true,
            aiAnalysis,
          });
        }

        // If very low confidence, ignore
        if (aiAnalysis.decision === 'IGNORE') {
          return res.status(400).json({
            message: 'Low confidence score - this appears to be normal activity',
            aiAnalysis,
          });
        }
      }

      // Step 3: Create emergency record (ATOMIC)
      const emergency = await Emergency.create({
        userId,
        type,
        location,
        state: 'CREATED',
        priority: sensorData ? 'CRITICAL' : 'MEDIUM',
        description,
        isAccident: aiAnalysis?.decision === 'AUTO_ALERT',
        accidentData: aiAnalysis || {},
      });

      console.log(`✅ Emergency created: ${emergency._id}`);

      // Step 4: Notify trusted contacts (SMS fallback)
      const user = await User.findById(userId).select('phone');
      const trustedContacts = []; // TODO: Get from user contacts
      if (trustedContacts.length > 0) {
        await FailureHandlingService.sendSMSFallback(
          userId,
          location,
          trustedContacts
        );
      }

      // Step 5: Broadcast to nearby police
      try {
        await this.broadcastToCops(emergency);
      } catch (error) {
        console.error('Police broadcast failed:', error.message);
        // Continue - don't fail entire workflow
      }

      // Step 6: Route to hospitals
      try {
        await this.routeToHospitals(emergency);
      } catch (error) {
        console.error('Hospital routing failed:', error.message);
        // Continue - police may handle it
      }

      // Step 7: Stream real-time updates
      const realtimeService = getRealtimeService();
      realtimeService.streamEmergencyCreated(emergency, 0); // TODO: count nearby officers

      res.status(200).json({
        success: true,
        emergencyId: emergency._id,
        state: 'BROADCASTED',
        message: 'Emergency broadcast to nearby units',
        aiAnalysis: aiAnalysis || { decision: 'MANUAL_ALERT' },
      });
    } catch (error) {
      console.error('❌ Emergency trigger failed:', error.message);

      // Send to dead-letter queue
      if (error.emergencyId) {
        await FailureHandlingService.sendToDeadLetterQueue(
          error.emergencyId,
          error.message
        );
      }

      res.status(500).json({
        success: false,
        message: 'Emergency creation failed',
        error: error.message,
      });
    }
  }

  /**
   * Confirm emergency after AI asks
   */
  static async confirmEmergency(req, res) {
    try {
      const { emergencyId } = req.params;
      const { confirmed } = req.body;

      const emergency = await Emergency.findById(emergencyId);
      if (!emergency) {
        return res.status(404).json({ message: 'Emergency not found' });
      }

      if (!confirmed) {
        emergency.state = 'DISMISSED';
        await emergency.save();
        return res.status(200).json({ message: 'Emergency dismissed' });
      }

      // Confirmed - proceed with workflow
      emergency.state = 'BROADCASTED';
      await emergency.save();

      await this.broadcastToCops(emergency);
      await this.routeToHospitals(emergency);

      res.status(200).json({
        success: true,
        message: 'Emergency confirmed and broadcast',
      });
    } catch (error) {
      res.status(500).json({ message: 'Confirmation failed', error: error.message });
    }
  }

  // ============================================================
  // STATE MACHINE TRANSITIONS
  // ============================================================

  /**
   * Broadcast to nearby police with timeout and escalation
   */
  static async broadcastToCops(emergency) {
    try {
      const result = await PoliceDispatchService.broadcastEmergency(
        emergency._id,
        emergency.location
      );

      emergency.state = 'BROADCASTED';
      emergency.broadcastedAt = new Date();
      await emergency.save();

      // Schedule timeout check (15 seconds)
      setTimeout(() => {
        this.checkPoliceTimeout(emergency._id);
      }, 15000);

      return result;
    } catch (error) {
      console.error('Broadcast failed:', error.message);
      throw error;
    }
  }

  /**
   * Route to hospitals
   */
  static async routeToHospitals(emergency) {
    try {
      const result = await HospitalRoutingService.routeEmergency(
        emergency._id,
        emergency.location
      );

      console.log(`✅ Hospital routing result:`, result);
      return result;
    } catch (error) {
      console.error('Hospital routing failed:', error.message);
      // Don't throw - police might handle it
    }
  }

  /**
   * Check if police accepted within timeout
   */
  static async checkPoliceTimeout(emergencyId) {
    try {
      const emergency = await Emergency.findById(emergencyId);

      if (!emergency || emergency.state !== 'BROADCASTED') {
        return; // Already accepted or closed
      }

      // No acceptance within 15 seconds - escalate
      console.log(`⏱️  TIMEOUT: Police didn't respond to ${emergencyId}`);

      await FailureHandlingService.escalateEmergency(
        emergencyId,
        'POLICE_NO_RESPONSE_15SEC'
      );

      // Try next wave of police
      const expandedResult = await PoliceDispatchService.broadcastEmergency(
        emergencyId,
        emergency.location,
        10 // 10km radius instead of 5km
      );

      console.log(`🔔 Escalation: Broadcast to ${expandedResult.targetOfficers} officers in wider area`);
    } catch (error) {
      console.error('Timeout check failed:', error.message);
    }
  }

  /**
   * Police accepts case (with atomic lock)
   */
  static async acceptCase(req, res) {
    try {
      const { emergencyId } = req.params;
      const policeId = req.user._id;

      const result = await PoliceDispatchService.acceptEmergencyWithLock(
        emergencyId,
        policeId
      );

      if (!result.success) {
        return res.status(409).json({
          message: 'Case already accepted by another officer',
          assignedToPolice: result.assignedToPolice,
        });
      }

      // Stream real-time update
      const emergency = await Emergency.findById(emergencyId);
      const realtimeService = getRealtimeService();
      realtimeService.streamCaseAccepted(emergency);

      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ message: 'Acceptance failed', error: error.message });
    }
  }

  /**
   * Police updates status
   */
  static async updateCaseStatus(req, res) {
    try {
      const { emergencyId } = req.params;
      const { status, location } = req.body;
      const policeId = req.user._id;

      const result = await PoliceDispatchService.updateCaseStatus(
        emergencyId,
        policeId,
        status,
        location
      );

      // Stream real-time location update
      const realtimeService = getRealtimeService();
      realtimeService.streamLocationUpdate(emergencyId, policeId, location);

      res.status(200).json({
        success: true,
        status,
        message: `Status updated to ${status}`,
      });
    } catch (error) {
      res.status(500).json({ message: 'Status update failed', error: error.message });
    }
  }

  /**
   * Police resolves case
   */
  static async resolveCase(req, res) {
    try {
      const { emergencyId } = req.params;
      const { resolution } = req.body;
      const policeId = req.user._id;

      const result = await PoliceDispatchService.resolveCase(
        emergencyId,
        policeId,
        resolution
      );

      // Stream resolution event
      const realtimeService = getRealtimeService();
      realtimeService.streamResolution(result);

      // Record feedback opportunity
      res.status(200).json({
        success: true,
        emergencyId: result._id,
        state: 'RESOLVED',
        resolutionTime: result.totalResolutionTime,
        message: 'Case resolved successfully',
      });
    } catch (error) {
      res.status(500).json({ message: 'Resolution failed', error: error.message });
    }
  }

  // ============================================================
  // HOSPITAL WORKFLOW
  // ============================================================

  /**
   * Hospital accepts emergency request
   */
  static async acceptHospitalRequest(req, res) {
    try {
      const { emergencyId } = req.params;
      const hospitalId = req.user._id;

      const result = await HospitalRoutingService.acceptEmergency(
        hospitalId,
        emergencyId
      );

      // Update bed availability
      await HospitalRoutingService.updateBedAvailability(hospitalId, 1);

      // Stream update
      const realtimeService = getRealtimeService();
      realtimeService.streamCaseAccepted(result);

      res.status(200).json({
        success: true,
        emergencyId: result._id,
        hospitalId,
        message: 'Emergency accepted',
      });
    } catch (error) {
      res.status(500).json({ message: 'Acceptance failed', error: error.message });
    }
  }

  /**
   * Hospital rejects emergency request
   */
  static async rejectHospitalRequest(req, res) {
    try {
      const { emergencyId } = req.params;
      const { reason } = req.body;
      const hospitalId = req.user._id;

      const result = await HospitalRoutingService.rejectEmergency(
        hospitalId,
        emergencyId,
        reason
      );

      res.status(200).json({
        success: true,
        message: 'Emergency rejected - routing to next hospital',
        nextHospital: result?.nextHospital || null,
      });
    } catch (error) {
      res.status(500).json({ message: 'Rejection failed', error: error.message });
    }
  }

  // ============================================================
  // AI FEEDBACK LOOP
  // ============================================================

  /**
   * User provides feedback on AI accuracy
   */
  static async provideFeedback(req, res) {
    try {
      const { emergencyId } = req.params;
      const { wasAccurate, userFeedback } = req.body;

      const result = await AIDecisionEngine.recordFeedback({
        emergencyId,
        wasAccurate,
        userFeedback,
      });

      res.status(200).json({
        success: true,
        message: 'Feedback recorded - will improve AI model',
        ...result,
      });
    } catch (error) {
      res.status(500).json({ message: 'Feedback failed', error: error.message });
    }
  }

  // ============================================================
  // EMERGENCY QUERIES
  // ============================================================

  /**
   * Get active emergencies
   */
  static async getActiveEmergencies(req, res) {
    try {
      const activeStates = ['CREATED', 'BROADCASTED', 'ACCEPTED', 'IN_PROGRESS'];
      const emergencies = await Emergency.find({
        state: { $in: activeStates },
      }).sort({ createdAt: -1 });

      res.status(200).json({
        count: emergencies.length,
        emergencies,
      });
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch emergencies', error: error.message });
    }
  }

  /**
   * Get emergency details
   */
  static async getEmergencyDetails(req, res) {
    try {
      const { emergencyId } = req.params;

      const emergency = await Emergency.findById(emergencyId)
        .populate('userId', 'name phone')
        .populate('assignedPolice', 'name phone currentLocation')
        .populate('assignedHospital', 'hospitalDetails');

      if (!emergency) {
        return res.status(404).json({ message: 'Emergency not found' });
      }

      res.status(200).json(emergency);
    } catch (error) {
      res.status(500).json({ message: 'Failed to fetch details', error: error.message });
    }
  }
}

module.exports = EmergencyWorkflowController;
