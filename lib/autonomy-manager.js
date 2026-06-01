const CONFIRMATION_POINTS = {
  PHASE_BOUNDARY: 'phase_boundary',
  NOTE_TYPE_SELECTION: 'note_type_selection',
  PLAN_APPROVAL: 'plan_approval',
  FINAL_REVIEW: 'final_review'
};

const CRITICAL_POINTS = [
  CONFIRMATION_POINTS.NOTE_TYPE_SELECTION,
  CONFIRMATION_POINTS.PLAN_APPROVAL,
  CONFIRMATION_POINTS.FINAL_REVIEW
];

class AutonomyManager {
  constructor(level) {
    this.level = Math.max(0, Math.min(3, level));
  }

  shouldConfirm(phase, point) {
    switch (this.level) {
      case 0:
        return true;
      case 1:
        // Level 1: confirmation at phase boundaries
        // 'end' is always a boundary (end of current phase)
        // 'start' is a boundary only if it's not the first phase (phase = 'collect')
        if (point === 'end') return true;
        if (point === 'start' && phase !== 'collect') return true;
        return false;
      case 2:
        return CRITICAL_POINTS.includes(point);
      case 3:
        return point === CONFIRMATION_POINTS.FINAL_REVIEW;
      default:
        return true;
    }
  }

  getStatusMessage(fromPhase, toPhase) {
    return `[Auto] ${fromPhase} complete, proceeding to ${toPhase} (autonomy level: ${this.level})`;
  }

  getLevel() {
    return this.level;
  }
}

module.exports = { AutonomyManager, CONFIRMATION_POINTS, CRITICAL_POINTS };
