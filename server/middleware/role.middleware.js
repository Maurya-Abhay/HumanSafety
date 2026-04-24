// Role-based authorization middleware

const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Unauthorized: No user' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ 
        message: `Forbidden: Requires one of roles: ${allowedRoles.join(', ')}`,
        requiredRoles: allowedRoles,
        userRole: req.user.role,
      });
    }

    next();
  };
};

const requireApproved = (req, res, next) => {
  if (req.user.status !== 'active') {
    return res.status(403).json({ 
      message: `Account status: ${req.user.status}`,
      status: req.user.status,
      rejectionReason: req.user.rejectionReason,
    });
  }
  next();
};

const requireNotBlocked = (req, res, next) => {
  if (req.user.isBlocked) {
    return res.status(403).json({ 
      message: `Account blocked: ${req.user.blockReason || 'No reason provided'}`,
      blockReason: req.user.blockReason,
    });
  }
  next();
};

module.exports = { requireRole, requireApproved, requireNotBlocked };
