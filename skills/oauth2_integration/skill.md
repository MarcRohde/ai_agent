# Skill: OAuth2 Integration

## Description
Implement OAuth2 authentication flows (device code, authorization code, client credentials) for API integrations. Handle token acquisition, refresh, caching, and secure storage. This skill covers Microsoft Identity Platform, generic OAuth2 providers, and token lifecycle management.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `provider` | Yes | OAuth2 provider (e.g., Microsoft, Google, generic) |
| `flow_type` | Yes | OAuth2 flow (device_code, authorization_code, client_credentials, refresh_token) |
| `scopes` | Yes | List of required permission scopes |
| `client_id` | Yes | Application client ID (or env var reference) |
| `tenant_id` | Conditional | Required for Microsoft multi-tenant apps |
| `token_cache_strategy` | No | How to cache tokens (memory, file, env_var) - default: memory |

## Steps

1. **Identify OAuth2 Provider and Flow** — Determine the authentication endpoint, token endpoint, and flow requirements. For Microsoft Identity Platform, use device code flow for CLI/scripts without browser redirect.

2. **Validate Scopes** — Ensure requested scopes match the API's requirements. For Microsoft Graph/EWS: `https://graph.microsoft.com/.default` or `https://outlook.office365.com/EWS.AccessAsUser.All`.

3. **Implement Token Acquisition** — Build the authentication flow:
   - **Device Code**: Poll token endpoint after displaying user code
   - **Authorization Code**: Handle redirect callback and exchange code for token
   - **Client Credentials**: Direct token request with client secret/certificate
   - Store access token, refresh token (if provided), and expiration time

4. **Add Token Refresh Logic** — Check token expiration before each API call. If expired and refresh token exists, exchange refresh token for new access token. Re-authenticate if refresh fails.

5. **Secure Credential Storage** — Never hardcode secrets. Use:
   - Environment variables for client IDs/tenant IDs
   - Secure stores (Windows Credential Manager, Azure Key Vault) for client secrets
   - Certificate-based authentication for production

6. **Error Handling** — Handle common OAuth2 errors:
   - `invalid_grant`: Re-authenticate
   - `expired_token`: Refresh token
   - `insufficient_scope`: Request additional scopes
   - `authorization_pending`: Continue polling (device code flow)

## Output

A reusable authentication module/function that returns a valid access token. Include token expiration checking and automatic refresh.

```powershell
# PowerShell Example
function Get-AccessToken {
    param([string]$TenantId, [string]$ClientId, [string[]]$Scopes)
    
    # Check cached token expiration
    if ($script:TokenExpiresAt -gt [DateTime]::UtcNow) {
        return $script:AccessToken
    }
    
    # Device code flow implementation
    # Token refresh logic
    # Return valid access token
}
```

```python
# Python Example
class OAuth2Client:
    def __init__(self, client_id: str, scopes: list[str]):
        self.client_id = client_id
        self.scopes = scopes
        self._token = None
        self._expires_at = None
    
    def get_token(self) -> str:
        """Get valid access token, refreshing if needed"""
        if self._token and self._expires_at > datetime.utcnow():
            return self._token
        return self._acquire_new_token()
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `fetch_webpage` (to research provider-specific OAuth2 documentation)
- Environment variable configuration scripts

## Tags
`authentication`, `oauth2`, `api-integration`, `security`, `microsoft-identity`
