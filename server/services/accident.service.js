const calculateAccidentConfidence = (data) => {
  let score = 0;
  let factors = [];

  if (data.impact && data.impact > 5) {
    score += 30;
    factors.push('Impact detected (+30)');
  }

  if (data.speedDrop && data.speedDrop > 20) {
    score += 25;
    factors.push('Sudden speed drop (+25)');
  }

  if (data.inactivity && data.inactivity > 30000) {
    score += 20;
    factors.push('User inactivity (+20)');
  }

  if (data.sound && data.sound > 80) {
    score += 15;
    factors.push('High sound level (+15)');
  }

  if (data.motionAnomalies > 0) {
    score += Math.min(data.motionAnomalies * 5, 10);
    factors.push(`Motion anomalies (+${Math.min(data.motionAnomalies * 5, 10)})`);
  }

  return {
    score: Math.min(score, 100),
    isAccident: score >= 60,
    confidence: Math.min(score, 100),
    factors,
  };
};

module.exports = { calculateAccidentConfidence };
