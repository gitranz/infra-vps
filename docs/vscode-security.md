# Securing code-server on your VPS

This document outlines the security assessment and recommendations for your `code-server` setup, which is exposed to the internet via an Nginx reverse proxy with Let's Encrypt SSL.

## Current Security Assessment
**Status:** ⚠️ **Moderately Secure (Acceptable for low-risk, risky for critical data)**

Your current setup has the **minimum required baseline** for internet exposure:
1.  **HTTPS (Let's Encrypt):** Ensures all traffic between your browser and `code-server` is encrypted, preventing interception of sensitive data like your password and code.
2.  **Reverse Proxy (Nginx):** Nginx Proxy Manager acts as an intermediary, hiding the direct `code-server` container from the public internet.
3.  **Password Authentication:** `code-server` itself requires a password to log in, preventing unauthorized access.

**Major Risks in your current setup:**

*   **Single Point of Failure (Authentication):** The built-in `code-server` password is the primary defense. If this password is compromised (e.g., via brute-force attack or a weak password), an attacker gains full access.
*   **Broad Filesystem Exposure:** Your `docker-compose.yml` mounts `/home/chrisadmin/workspace:/workspace` into the `code-server` container. Since the container runs with your user's PUID/PGID (`PUID=1001`), **anyone who successfully logs into `code-server` has full read, write, and delete access to all files within `/home/chrisadmin/workspace` on your host machine.** This is a significant risk if the authentication is breached.
*   **Public Exposure Surface:** By exposing `code-server` to the entire internet ("access from everywhere"), you increase its vulnerability to potential zero-day exploits in `code-server` itself, Nginx, or any other underlying components.

---

## Recommendations to Harden Security

To significantly improve the security of your `code-server` instance, implement the following recommendations:

### 1. Add an Additional Authentication Layer (High Priority)
The built-in `code-server` password provides basic protection. Integrating an additional authentication layer in front of `code-server` will dramatically increase security.

*   **Option A: Nginx Proxy Manager Basic Authentication (Easiest)**
    *   **How to implement:** In Nginx Proxy Manager, navigate to the "Access Lists" section. Create a new access list with a strong username and password. Then, apply this access list to your `code-server` proxy host.
    *   **Benefit:** This adds a second login prompt that users must pass *before* their request is even forwarded to the `code-server` container. It acts as an effective initial barrier against unauthorized access.

*   **Option B: Authelia/Authentik for Multi-Factor Authentication (Best Practice)**
    *   **How to implement:** Deploy an identity provider like Authelia or Authentik as an additional Docker container. Configure Nginx Proxy Manager to integrate with it for authentication and authorization.
    *   **Benefit:** Provides **Multi-Factor Authentication (2FA)**, which is essential for internet-facing services. Even if an attacker obtains your password, they cannot log in without the second factor (e.g., a TOTP code from an authenticator app). This effectively neutralizes password guessing attacks.

### 2. Restrict Network Access (If Possible)
If you don't truly need `code-server` to be accessible from *anywhere* in the world, consider restricting network access.

*   **IP Whitelisting (Nginx Proxy Manager)**
    *   **How to implement:** If "everywhere" primarily means a few specific locations (e.g., your home, office), you can restrict access to those static IP addresses. In Nginx Proxy Manager's "Access Lists," specify allowed source IP ranges.
    *   **Benefit:** Reduces the attack surface by only allowing connections from trusted networks.

*   **VPN / Overlay Network (The "Gold Standard" for Personal Use)**
    *   **How to implement:** Install a VPN solution like **Tailscale** or **WireGuard** on your VPS and all your client devices (laptop, phone, tablet).
    *   **How it works:** Instead of accessing `code-server` via a public domain name, you would connect to your VPN, and then access `code-server` using its internal network IP (e.g., `http://100.x.y.z:8443`).
    *   **Benefit:** The `code-server` instance becomes completely invisible to the public internet. This eliminates the vast majority of external attack vectors, as no public ports are open for `code-server`.

### 3. Secure the Nginx Configuration (Nginx Proxy Manager)
Review and update your Nginx Proxy Manager configuration for your `code-server` proxy host.

*   **Essential Settings:**
    *   ✅ **Force SSL:** Ensure this option is checked to automatically redirect all HTTP traffic to HTTPS.
    *   ✅ **HSTS Enabled:** Enable HTTP Strict Transport Security (HSTS). This tells browsers to *only ever* connect to your domain via HTTPS, preventing downgrade attacks.
    *   ✅ **HTTP/2 Support:** Enable HTTP/2 for improved performance and efficiency.

*   **Advanced Security Headers:**
    *   In the "Advanced" tab (Custom Nginx Configuration) of your proxy host, add the following headers to mitigate common web vulnerabilities:

    ```nginx
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    ```
    *   **Explanation:**
        *   `X-Frame-Options "SAMEORIGIN"`: Prevents clickjacking attacks by disallowing your site from being embedded in iframes on other domains.
        *   `X-XSS-Protection "1; mode=block"`: Enables the browser's XSS (Cross-Site Scripting) filter, preventing reflected XSS attacks.
        *   `X-Content-Type-Options "nosniff"`: Prevents browsers from "sniffing" MIME types, reducing the risk of MIME-type confusion attacks.

### 4. Hardening the `code-server` Container and Host
*   **Implement Fail2Ban (Host Level)**
    *   **How to implement:** Install `fail2ban` on your VPS host machine. Configure it to monitor Nginx access logs for HTTP status codes indicating authentication failures (e.g., 401, 403) from your `code-server` domain.
    *   **Benefit:** Automatically bans IP addresses that attempt too many failed logins, protecting against brute-force attacks.

*   **Review Volume Mounts (`docker-compose.yml`)**
    *   **Action:** Carefully examine the volumes mounted into your `code-server` container (`/home/chrisadmin/workspace:/workspace`).
    *   **Recommendation:** Only mount the *absolute minimum* necessary directories or files into the container. For instance, if you only work on projects within `/home/chrisadmin/workspace/my_project`, change the mount to `/home/chrisadmin/workspace/my_project:/workspace`.
    *   **Benefit:** Reduces the scope of damage if the `code-server` container is compromised, as an attacker would only have access to the mounted directory, not your entire workspace.

---

### Summary Security Checklist
Prioritize these actions to enhance your `code-server` security:

1.  [ ] **Immediate:** Enable "Force SSL" and "HSTS" in Nginx Proxy Manager for your `code-server` host.
2.  [ ] **Recommended:** Implement Nginx Proxy Manager Basic Authentication (Option 1A) or deploy Authelia/Authentik for 2FA (Option 1B).
3.  [ ] **Strongest Security (If Applicable):** Consider replacing public exposure with a VPN solution like Tailscale (Option 2).
4.  [ ] **Good Practice:** Add advanced security headers to your Nginx Proxy Manager configuration (Option 3).
5.  [ ] **Host Security:** Install and configure Fail2Ban on your VPS (Option 4).
6.  [ ] **Least Privilege:** Review and tighten your Docker volume mounts to expose only necessary directories (Option 4).
