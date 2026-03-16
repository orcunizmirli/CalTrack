/**
 * Parse a duration string like "15m", "7d", "3600s" into seconds.
 * Supported suffixes: s (seconds), m (minutes), h (hours), d (days).
 */
export function parseDurationToSeconds(duration: string): number {
  const match = duration.match(/^(\d+)([smhd])$/);
  if (!match) return 7 * 24 * 3600; // default 7 days
  const value = parseInt(match[1]);
  switch (match[2]) {
    case 's': return value;
    case 'm': return value * 60;
    case 'h': return value * 3600;
    case 'd': return value * 86400;
    default: return 7 * 86400;
  }
}
