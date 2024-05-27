#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 [-l] [-f <ftl_branch>] [-c <core_branch>] [-w <web_branch>] [-t <tag>] [use_cache]"
    echo ""
    echo "Options:"
    echo "  -f, --ftlbranch <branch>         Specify FTL branch (cannot be used in conjunction with -l)"
    echo "  -c, --corebranch <branch>        Specify Core branch"
    echo "  -w, --webbranch <branch>         Specify Web branch"
    echo "  -p, --paddbranch <branch>        Specify PADD branch"
    echo "  -t, --tag <tag>                  Specify Docker image tag (default: pihole)"
    echo "  -l, --local                      Use locally built FTL binary (requires src/pihole-FTL file)"
    echo "  -v, --piholedockertag <version>  Specify a version number for the image"
    echo "                                     default: dev-unknown - must match following pattern:"
    echo "                                     https://regex101.com/r/RsENuz/1)"
    echo "  use_cache                        Enable caching (by default --no-cache is used)"
    echo ""
    echo "If no options are specified, the following command will be executed:"
    echo "  docker buildx build src/. --tag pihole --load --no-cache"
    exit 1
}

# Set default values
DOCKER_BUILD_CMD="docker buildx build src/. --load --no-cache"
FLAG_LOCAL_FTL=false
FLAG_REMOTE_FTL=false
TAG=pihole

# Parse all command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -l | --local)
        if [ "$FLAG_REMOTE_FTL" = true ]; then
            echo "Error: Both -l and -f cannot be used together."
            echo ""
            usage
        fi
        FLAG_LOCAL_FTL=true
        shift
        ;;
    -f | --ftlbranch)
        if [ "$FLAG_LOCAL_FTL" = true ]; then
            # Local and remote FTL branches are not allowed at the same time
            echo "Error: Both -l and -f cannot be used together."
            echo ""
            usage
        fi
        FLAG_REMOTE_FTL=true
        FTL_BRANCH="$2"
        shift
        shift
        ;;
    -c | --corebranch)
        CORE_BRANCH="$2"
        shift
        shift
        ;;
    -w | --webbranch)
        WEB_BRANCH="$2"
        shift
        shift
        ;;
    -t | --tag)
        TAG="$2"
        shift
        shift
        ;;
    -v | --piholedockertag)
        PIHOLE_DOCKER_TAG="$2"
        shift
        shift
        ;;
    -p | --paddbranch)
        PADD_BRANCH="$2"
        shift
        shift
        ;;
    use_cache)
        DOCKER_BUILD_CMD=${DOCKER_BUILD_CMD/--no-cache/}
        shift
        ;;
    *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
done

# Add the tag to the build command
DOCKER_BUILD_CMD+=" --tag $TAG"

# Check if PIHOLE_DOCKER_TAG is set
if [ ! -z "$PIHOLE_DOCKER_TAG" ]; then
    # Add PIHOLE_DOCKER_TAG to the --tag argument
    DOCKER_BUILD_CMD+=":$PIHOLE_DOCKER_TAG"
    # Add PIHOLE_DOCKER_TAG to the build arguments
    DOCKER_BUILD_CMD+=" --build-arg PIHOLE_DOCKER_TAG=$PIHOLE_DOCKER_TAG"
fi

# Is this a local build?
if [ "$FLAG_LOCAL_FTL" = true ]; then
    if [ ! -f "src/pihole-FTL" ]; then
        echo "File 'src/pihole-FTL' not found. Exiting."
        exit 1
    fi
    DOCKER_BUILD_CMD+=" --build-arg FTL_SOURCE=local"
fi

# Check if FTL_BRANCH is set
if [ ! -z "$FTL_BRANCH" ]; then
    DOCKER_BUILD_CMD+=" --build-arg FTL_BRANCH=$FTL_BRANCH"
fi

# Check if CORE_BRANCH is set
if [ ! -z "$CORE_BRANCH" ]; then
    DOCKER_BUILD_CMD+=" --build-arg CORE_BRANCH=$CORE_BRANCH"
fi

# Check if WEB_BRANCH is set
if [ ! -z "$WEB_BRANCH" ]; then
    DOCKER_BUILD_CMD+=" --build-arg WEB_BRANCH=$WEB_BRANCH"
fi

# Check if PADD_BRANCH is set
if [ ! -z "$PADD_BRANCH" ]; then
    DOCKER_BUILD_CMD+=" --build-arg PADD_BRANCH=$PADD_BRANCH"
fi


# Execute the docker build command
echo "Executing command: $DOCKER_BUILD_CMD"
eval $DOCKER_BUILD_CMD
