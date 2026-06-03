#!/usr/bin/env bash
set -euo pipefail

if [ "${CODEX_ENABLE_FIREWALL:-0}" != "1" ]; then
  printf 'Codex network firewall disabled; set CODEX_ENABLE_FIREWALL=1 to enable it.\n'
  exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
  printf 'ERROR: init-codex-firewall.sh must run as root.\n' >&2
  exit 1
fi

for tool in dig ipset iptables; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'ERROR: %s is required for the Codex network firewall.\n' "$tool" >&2
    exit 1
  fi
done

allowed_domains_file="${CODEX_ALLOWED_DOMAINS_FILE:-/workspace/.devcontainer/codex-allowed-domains.txt}"
if [ ! -f "$allowed_domains_file" ]; then
  printf 'ERROR: allowed domains file is missing: %s\n' "$allowed_domains_file" >&2
  exit 1
fi

mapfile -t allowed_domains < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$allowed_domains_file")
if [ "${#allowed_domains[@]}" -eq 0 ]; then
  printf 'ERROR: no allowed domains configured in %s\n' "$allowed_domains_file" >&2
  exit 1
fi

ipset create codex-allowed-domains hash:net -exist
ipset flush codex-allowed-domains

for domain in "${allowed_domains[@]}"; do
  printf 'Resolving %s\n' "$domain"
  ips="$(dig +short A "$domain" | sed '/^[[:space:]]*$/d')"
  if [ -z "$ips" ]; then
    printf 'ERROR: failed to resolve %s\n' "$domain" >&2
    exit 1
  fi

  while IFS= read -r ip; do
    if [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
      ipset add codex-allowed-domains "$ip" -exist
    fi
  done <<< "$ips"
done

iptables -N CODEX-FIREWALL 2>/dev/null || true
iptables -F CODEX-FIREWALL
iptables -A CODEX-FIREWALL -o lo -j ACCEPT
iptables -A CODEX-FIREWALL -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A CODEX-FIREWALL -p udp --dport 53 -j ACCEPT
iptables -A CODEX-FIREWALL -p tcp --dport 53 -j ACCEPT
iptables -A CODEX-FIREWALL -m set --match-set codex-allowed-domains dst -j ACCEPT
iptables -A CODEX-FIREWALL -j REJECT --reject-with icmp-admin-prohibited

iptables -C OUTPUT -j CODEX-FIREWALL 2>/dev/null || iptables -I OUTPUT 1 -j CODEX-FIREWALL

if command -v ip6tables >/dev/null 2>&1; then
  ip6tables -N CODEX-FIREWALL 2>/dev/null || true
  ip6tables -F CODEX-FIREWALL
  ip6tables -A CODEX-FIREWALL -o lo -j ACCEPT
  ip6tables -A CODEX-FIREWALL -m state --state ESTABLISHED,RELATED -j ACCEPT
  ip6tables -A CODEX-FIREWALL -j REJECT --reject-with icmp6-adm-prohibited
  ip6tables -C OUTPUT -j CODEX-FIREWALL 2>/dev/null || ip6tables -I OUTPUT 1 -j CODEX-FIREWALL
fi

printf 'Codex network firewall enabled with %s allowed domain(s).\n' "${#allowed_domains[@]}"
