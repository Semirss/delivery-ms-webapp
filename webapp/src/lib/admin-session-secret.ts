export function adminSessionSecret() {
  for (const secret of [process.env.JWT_SECRET, process.env.DRIVER_SESSION_SECRET]) {
    if (secret && secret.length >= 32) return secret;
  }
  return null;
}
