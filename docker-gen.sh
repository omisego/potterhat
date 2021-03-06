#!/bin/sh

print_usage() {
    printf "Usage: %s [CONFIG..] [OPTS]\\n" "$0"
    printf "\\n"
    printf "Generates a Docker-Compose configuration overrides for various\\n"
    printf "purposes. This script will output to STDOUT, it is expected that\\n"
    printf "a user will pipe its output into a file. For example:\\n"
    printf "\\n"
    printf "     %s > docker-compose.override.yml\\n" "$0"
    printf "\\n"
    printf "OPTS:\\n"
    printf "\\n"
    printf "     -h         Prints this help.\\n"
    printf "     -d         Generates a development override.\\n"
    printf "\\n"
    printf "CONFIG:\\n"
    printf "\\n"
    printf "     -i image   Specify an alternative eWallet image name.\\n"
    printf "     -n network Specify an external network.\\n"
    printf "     -f env     Specify an env file.\\n"
    printf "\\n"
}

ARGS=$(getopt hdi:n:c:r:w:f: "$@" 2>/dev/null)

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "$ARGS"

IMAGE_NAME=""
EXTERNAL_NETWORK=""
DEV_MODE=0

while true; do
    case "$1" in
        -i ) IMAGE_NAME=$2;              shift;shift;;
        -n ) EXTERNAL_NETWORK=$2;        shift;shift;;
        -c ) NODE_CLIENT_TYPE=$2;        shift;shift;;
        -r ) NODE_RPC_URI=$2;            shift;shift;;
        -w ) NODE_WS_URI=$2;             shift;shift;;
        -f ) ENV_FILE=$2;                shift;shift;;
        -d ) DEV_MODE=1;                 shift;;
        -h ) print_usage;                exit 2;;
        -- ) shift; break;;
        *  ) break;;
    esac
done

[ -z "$NODE_CLIENT_TYPE" ] && NODE_CLIENT_TYPE="geth"
[ -z "$NODE_RPC_URI" ]     && NODE_RPC_URI="http://your_rpc_uri:8545"
[ -z "$NODE_WS_URI" ]      && NODE_WS_URI="ws://your_websocket_uri:8546"

if [ -z "$IMAGE_NAME" ]; then
   if [ $DEV_MODE = 1 ]; then
       IMAGE_NAME="omisegoimages/ewallet-builder:v1.2"
   else
       IMAGE_NAME="omisego/potterhat:stable"
   fi
fi

YML_SERVICES="
  potterhat:
    image: $IMAGE_NAME
    environment:
      POTTERHAT_NODE_1_ID: \"default_node\"
      POTTERHAT_NODE_1_LABEL: \"Default Node\"
      POTTERHAT_NODE_1_CLIENT_TYPE: \"$NODE_CLIENT_TYPE\"
      POTTERHAT_NODE_1_RPC: \"$NODE_RPC_URI\"
      POTTERHAT_NODE_1_WS: \"$NODE_WS_URI\"
      POTTERHAT_NODE_1_PRIORITY: 10\
" # EOF

if [ -n "$ENV_FILE" ]; then
    YML_SERVICES="$YML_SERVICES
    env_file:
      - .env\
" # EOF
fi

if [ $DEV_MODE = 1 ]; then
    YML_SERVICES="$YML_SERVICES
    user: root
    volumes:
      - .:/app
      - potterhat-deps:/app/deps
      - potterhat-builds:/app/_build
    working_dir: /app\
" # EOF

    YML_VOLUMES="
  potterhat-deps:
  potterhat-builds:\
" # EOF
fi

if [ -n "$EXTERNAL_NETWORK" ]; then
    YML_NETWORKS="
  intnet:
    external:
      name: $EXTERNAL_NETWORK\
" # EOF
fi

printf "version: \"3\"\\n"
if [ -n "$YML_SERVICES" ]; then printf "\\nservices:%s\\n" "$YML_SERVICES"; fi
if [ -n "$YML_NETWORKS" ]; then printf "\\nnetworks:%s\\n" "$YML_NETWORKS"; fi
if [ -n "$YML_VOLUMES" ];  then printf "\\nvolumes:%s\\n"  "$YML_VOLUMES";  fi
