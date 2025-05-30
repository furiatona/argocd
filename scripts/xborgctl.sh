#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: xborgctl.sh
# Author: Dheny (@furiatona on GitHub)
# Description: All-in-one script for application deployment
# -----------------------------------------------------------------------------

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FORCE=false
PIPELINE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --force)
            FORCE=true
            shift
            ;;
        --pipeline)
            PIPELINE=true
            shift
            ;;
        --local)
            ENV_FILE="$(dirname "$0")/../.env"
            if [[ -f "${ENV_FILE}" ]]; then
            echo -e "${YELLOW}Loading .env for local environment${NC}"
            set -a # auto-export all variables
            source "${ENV_FILE}"
            set +a
            else
            echo -e "${RED}.env file not found at ${ENV_FILE}${NC}"
            exit 1
            fi
            shift
            ;;
        --help|-h)
            echo -e "${GREEN}Usage: $0 [--local|--pipeline|--force]${NC}"
            echo -e "${YELLOW}Only one argument can be used at a time.${NC}"
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

CLUSTER_ISSUER_NAME="letsencrypt"
DOMAIN="${DOMAIN:-}"
EMAIL="${EMAIL:-}"
APP_NAME="${APP_NAME:-}"
FLAT_DOMAIN="${DOMAIN//./}"
CERT_NAME="${FLAT_DOMAIN}-cert"
CERT_MANAGER_DIR="$(dirname "$0")/../cert-manager"
MANIFEST_DIR="$(dirname "$0")/../manifests"

is_valid_fqdn() {
    local domain=$1
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
        return 0
    else
        return 1
    fi
}

is_valid_email() {
    local email=$1
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

is_valid_app_name() {
    local app_name=$1
    if [[ "$app_name" =~ ^[a-z0-9-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

prompt_for_variables() {
    if [[ -z "${DOMAIN}" ]]; then
        read -p "Enter domain (e.g., example.com): " DOMAIN
        if [[ -z "${DOMAIN}" ]]; then
            echo -e "${RED}Domain cannot be empty.${NC}"
            exit 1
        fi
        if ! is_valid_fqdn "${DOMAIN}"; then
            echo -e "${RED}Invalid domain format. Please enter a valid FQDN (e.g., example.com).${NC}"
            exit 1
        fi
        FLAT_DOMAIN="${DOMAIN//./}"
        CERT_NAME="${FLAT_DOMAIN}-cert"
    fi
    if [[ -z "${EMAIL}" ]]; then
        read -p "Enter email for Let's Encrypt: " EMAIL
        if [[ -z "${EMAIL}" ]]; then
            echo -e "${RED}Email cannot be empty.${NC}"
            exit 1
        fi
        if ! is_valid_email "${EMAIL}"; then
            echo -e "${RED}Invalid email format. Please enter a valid email (e.g., user@example.com).${NC}"
            exit 1
        fi
    fi
    if [[ -z "${APP_NAME}" ]]; then
        read -p "Enter APP_NAME: (lowercase, must match with app repo name): " APP_NAME
        if [[ -z "${APP_NAME}" ]]; then
            echo -e "${RED}APP_NAME cannot be empty.${NC}"
            exit 1
        fi
        if ! is_valid_app_name "${APP_NAME}"; then
            echo -e "${RED}Invalid APP_NAME format. Please enter a valid APP_NAME (e.g., argocd).${NC}"
            exit 1
        fi
    fi
}

validate_variables() {
    if [[ -z "${DOMAIN}" ]]; then
        echo -e "${RED}DOMAIN variable not set. Please set it as an environment variable or run interactively.${NC}"
        exit 1
    fi
    if ! is_valid_fqdn "${DOMAIN}"; then
        echo -e "${RED}Invalid domain format. Please set a valid FQDN (e.g., example.com).${NC}"
        exit 1
    fi
    if [[ -z "${EMAIL}" ]]; then
        echo -e "${RED}EMAIL variable not set. Please set it as an environment variable or run interactively.${NC}"
        exit 1
    fi
    if ! is_valid_email "${EMAIL}"; then
        echo -e "${RED}Invalid email format. Please set a valid email (e.g., user@example.com).${NC}"
        exit 1
    fi
}

clusterissuer() {
    echo -e "${YELLOW}Generating ClusterIssuer ${CLUSTER_ISSUER_NAME}...${NC}"
    TEMPLATE_FILE="$(dirname "$0")/../templates/cluster-issuer.yaml"
    OUTPUT_FILE="${CERT_MANAGER_DIR}/${CLUSTER_ISSUER_NAME}-cluster-issuer.yaml"
    if [[ ! -d "${CERT_MANAGER_DIR}" ]]; then
        mkdir -p "${CERT_MANAGER_DIR}"
    fi
    if [[ -f "${OUTPUT_FILE}" && "${FORCE}" == false ]]; then
        echo -e "${RED}Output file ${OUTPUT_FILE} already exists. Use --force to overwrite.${NC}"
        exit 1
    fi
    if [[ ! -f "${TEMPLATE_FILE}" ]]; then
        echo -e "${RED}Template file ${TEMPLATE_FILE} not found.${NC}"
        exit 1
    fi
    export CLUSTER_ISSUER_NAME EMAIL
    envsubst '${CLUSTER_ISSUER_NAME} ${EMAIL}' < "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"
    echo -e "${GREEN}Generated ${OUTPUT_FILE}${NC}"
    echo -e "${YELLOW}Applying ClusterIssuer...${NC}"
    kubectl apply -f "${OUTPUT_FILE}"
    if kubectl get clusterissuer "${CLUSTER_ISSUER_NAME}" &>/dev/null; then
        echo -e "${GREEN}Cluster issuer '${CLUSTER_ISSUER_NAME}' created successfully.${NC}"
    else
        echo -e "${RED}Failed to create Cluster issuer '${CLUSTER_ISSUER_NAME}'.${NC}"
        exit 1
    fi
}

certificates() {
    echo -e "${YELLOW}Generating Certificate ${CERT_NAME}.yaml...${NC}"
    TEMPLATE_FILE="$(dirname "$0")/../templates/certificate.yaml"
    OUTPUT_FILE="${CERT_MANAGER_DIR}/${CERT_NAME}.yaml"
    if [[ ! -d "${CERT_MANAGER_DIR}" ]]; then
        mkdir -p "${CERT_MANAGER_DIR}"
    fi
    if [[ -f "${OUTPUT_FILE}" && "${FORCE}" == false ]]; then
        echo -e "${RED}Output file ${OUTPUT_FILE} already exists. Use --force to overwrite.${NC}"
        exit 1
    fi
    if [[ ! -f "${TEMPLATE_FILE}" ]]; then
        echo -e "${RED}Template file ${TEMPLATE_FILE} not found.${NC}"
        exit 1
    fi
    export CERT_NAME FLAT_DOMAIN DOMAIN CLUSTER_ISSUER_NAME
    envsubst '${CERT_NAME} ${FLAT_DOMAIN} ${DOMAIN} ${CLUSTER_ISSUER_NAME}' < "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"
    echo -e "${GREEN}Generated ${OUTPUT_FILE}${NC}"
    echo -e "${YELLOW}Applying Certificate...${NC}"
    kubectl apply -f "${OUTPUT_FILE}"
    if kubectl get -n istio-system certificate "${CERT_NAME}" &>/dev/null; then
        echo -e "${GREEN}Certificate '${DOMAIN}' created successfully.${NC}"
    else
        echo -e "${RED}Failed to create Certificate '${DOMAIN}'.${NC}"
        exit 1
    fi
}

services() {
    echo -e "${YELLOW}Generating services...${NC}"
    TEMPLATE_FILE="$(dirname "$0")/../templates/service.yaml"
    OUTPUT_FILE="${MANIFEST_DIR}/service.yaml"
     if [[ ! -d "${MANIFEST_DIR}" ]]; then
        mkdir -p "${MANIFEST_DIR}"
    fi
    if [[ -f "${OUTPUT_FILE}" && "${FORCE}" == false ]]; then
        echo -e "${RED}Output file ${OUTPUT_FILE} already exists. Use --force to overwrite.${NC}"
        exit 1
    fi
    if [[ ! -f "${TEMPLATE_FILE}" ]]; then
        echo -e "${RED}Template file ${TEMPLATE_FILE} not found.${NC}"
        exit 1
    fi
    export DOMAIN FLAT_DOMAIN APP_NAME
    envsubst '${DOMAIN} ${FLAT_DOMAIN} ${APP_NAME}' < "${TEMPLATE_FILE}" > "${OUTPUT_FILE}"
    echo -e "${GREEN}Generated ${OUTPUT_FILE}${NC}"
    echo -e "${YELLOW}Applying Services...${NC}"
    kubectl create namespace "${APP_NAME}" --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f "${OUTPUT_FILE}"
    if kubectl get -n "${APP_NAME}" gateway "${APP_NAME}-gateway" &>/dev/null && kubectl get -n "${APP_NAME}" virtualservice "${APP_NAME}-vs" &>/dev/null; then
        echo -e "${GREEN}Service '${APP_NAME}' created successfully.${NC}"
    else
        echo -e "${RED}Failed to create Service '${APP_NAME}'.${NC}"
        exit 1
    fi
}

main() {
    if [[ "${PIPELINE}" == false ]]; then
        prompt_for_variables
    fi
    validate_variables

    if ! command -v kubectl &>/dev/null; then
        echo -e "${RED}kubectl is not installed. Please install it first.${NC}"
        exit 1
    fi
    if ! command -v helm &>/dev/null; then
        echo -e "${RED}helm is not installed. Please install it first.${NC}"
        exit 1
    fi
    if kubectl get clusterissuer "${CLUSTER_ISSUER_NAME}" &>/dev/null; then
        echo -e "${GREEN}Cluster issuer '${CLUSTER_ISSUER_NAME}' found.${NC}"
    else
        echo -e "${RED}Cluster issuer '${CLUSTER_ISSUER_NAME}' not found. Creating...${NC}"
        clusterissuer
    fi
    if kubectl get certificate -n istio-system "${CERT_NAME}" &>/dev/null; then
        echo -e "${GREEN}Certificate for '${DOMAIN}' found.${NC}"
    else
        echo -e "${RED}Certificate for '${DOMAIN}' not found. Creating...${NC}"
        certificates
    fi
    if kubectl get -n "${APP_NAME}" gateway "${APP_NAME}-gateway" &>/dev/null && kubectl get -n "${APP_NAME}" virtualservice "${APP_NAME}-vs" &>/dev/null; then
        echo -e "${GREEN}Service '${APP_NAME}' found.${NC}"
    else
        echo -e "${RED}Service for '${APP_NAME}' not found. Creating...${NC}"
        services
    fi
}
main "$@"