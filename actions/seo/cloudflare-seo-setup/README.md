# Cloudflare SEO Setup Action

Automated Cloudflare SEO configuration that blocks development subdomains, creates redirects, and enables performance optimizations.

## 🎯 What it does

✅ **Blocks development subdomains** (dev, staging, test) from search engines  
✅ **Creates www → non-www redirects** (301 permanent)  
✅ **Enables Cloudflare optimizations** (Brotli, minification, HTTPS)  
✅ **Configures security settings** (Browser Integrity Check, Security Level)  
⚠️ **Note:** X-Robots-Tag headers require manual Transform Rules setup

## 🚀 Quick Start

### Basic Usage

```yaml
- name: Configure SEO
  uses: NextNodeSolutions/github-actions/actions/seo/cloudflare-seo-setup@main
  with:
    domain: 'yoursite.com'
    cloudflare-api-token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

### Full Configuration

```yaml
- name: Configure SEO
  uses: NextNodeSolutions/github-actions/actions/seo/cloudflare-seo-setup@main
  with:
    domain: 'yoursite.com'
    blocked-subdomains: 'dev,staging,test,preview'
    cloudflare-api-token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
    cloudflare-zone-id: ${{ secrets.CLOUDFLARE_ZONE_ID }}
    enable-www-redirect: true
    enable-optimizations: true
    dry-run: false
```

## 📋 Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `domain` | ✅ | - | Primary domain (e.g., `nextnode.fr`) |
| `blocked-subdomains` | ❌ | `dev,staging,test,preview` | Subdomains to block from search engines |
| `cloudflare-api-token` | ✅ | - | Cloudflare API token with Zone:Edit permissions |
| `cloudflare-zone-id` | ❌ | Auto-detected | Cloudflare Zone ID |
| `enable-www-redirect` | ❌ | `true` | Create www → non-www redirect |
| `enable-optimizations` | ❌ | `true` | Enable performance optimizations |
| `dry-run` | ❌ | `false` | Preview changes without applying |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `seo-configured` | Whether configuration was successful |
| `page-rules-created` | Number of page rules created |
| `redirects-created` | Number of redirect rules created |

## 🔧 Setup Requirements

### 1. Cloudflare API Token

Create a token with these permissions:
- **Zone:Edit** for your domain's zone
- **Zone:Read** for zone detection

Get your token at: https://dash.cloudflare.com/profile/api-tokens

### 2. GitHub Secrets

Add these secrets to your repository:

```
CLOUDFLARE_API_TOKEN=your_api_token_here
CLOUDFLARE_ZONE_ID=your_zone_id_here  # Optional, auto-detected
```

## ⚠️ Manual Steps Required

The action cannot configure X-Robots-Tag headers via API. After running the action:

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com) → Your Zone → Rules → Transform Rules
2. Create **HTTP Response Header** rules for each blocked subdomain:
   - **When:** hostname equals `dev.yoursite.com`
   - **Then:** Add header `X-Robots-Tag` with value `noindex, nofollow`

## 📊 Example Workflow

Complete SEO setup workflow:

```yaml
name: SEO Setup
on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['src/pages/sitemap.xml.ts', 'public/robots.txt']

jobs:
  seo:
    runs-on: ubuntu-latest
    steps:
      - uses: NextNodeSolutions/github-actions/actions/seo/cloudflare-seo-setup@main
        with:
          domain: 'yoursite.com'
          cloudflare-api-token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
      
      - name: Verify Setup
        run: |
          echo "✅ SEO configuration complete!"
          echo "🔍 Test: curl -I https://www.yoursite.com/"
          echo "🔍 Test: curl -I https://dev.yoursite.com/"
```

## 🎯 Integrated with DNS Workflow

**Recommended:** Use the DNS workflow with automatic SEO configuration:

```yaml
jobs:
  dns-and-seo:
    uses: NextNodeSolutions/github-actions/.github/workflows/dns.yml@main
    with:
      domain: 'yoursite.com'
      target: 'your-app.railway.app'
      blocked-subdomains: 'dev,staging,test'
      enable-seo-setup: true        # Automatic SEO (default)
      enable-optimizations: true    # Cloudflare optimizations
    secrets:
      CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

This configures both DNS records AND SEO settings in one workflow!

## 🔍 Verification

After setup, verify your configuration:

### Test Redirects
```bash
curl -I https://www.yoursite.com/
# Should return: HTTP/1.1 301 Moved Permanently
# Location: https://yoursite.com/
```

### Test Dev Blocking
```bash
curl -I https://dev.yoursite.com/
# Should return: X-Robots-Tag: noindex, nofollow
```

### Google Search Test
```
site:yoursite.com        # Should show your pages
site:dev.yoursite.com    # Should show no results
```

## 🐛 Troubleshooting

### Action Fails with "Zone not found"
- Verify your domain is added to Cloudflare
- Check the API token has Zone:Read permissions
- Provide `cloudflare-zone-id` manually

### Page Rules Not Created
- Ensure API token has Zone:Edit permissions
- Check Cloudflare plan limits (Free: 3 page rules, Pro: 20)
- Review action logs for specific errors

### Redirects Not Working
- Verify DNS records point to Cloudflare (orange cloud)
- Check page rule priority and matching patterns
- Test with `curl -I` to see actual headers

## 📚 Related Actions

- [DNS Cloudflare](../../dns.yml) - DNS record management
- [Railway Deploy](../../../deploy/railway-deploy) - Deploy to Railway
- [Railway Domain Setup](../../../domain/railway-domain-setup) - Configure custom domains

## 📝 License

Part of NextNode GitHub Actions collection.