# Multi-stage build for security and reduced image size
FROM docker.io/hashicorp/terraform:1.9.0 AS terraform-builder

FROM docker.io/library/python:3.12-slim

# Create a non-root user and group
RUN addgroup --system devgroup && adduser --system --ingroup devgroup devuser

# Install system dependencies and AWS CLI
# We use a single RUN command to minimize layers and clean up apt cache afterwards
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    jq \
    git \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip -q awscliv2.zip \
    && ./aws/install \
    && rm -rf awscliv2.zip ./aws \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy Terraform binary from the builder stage
COPY --from=terraform-builder /bin/terraform /usr/local/bin/terraform

# Set the working directory
WORKDIR /workspace

# Give the non-root user ownership of the workspace directory
RUN chown -R devuser:devgroup /workspace

# Switch to the non-root user
USER devuser

# Set entrypoint to bash for interactive usage
ENTRYPOINT ["/bin/bash"]
