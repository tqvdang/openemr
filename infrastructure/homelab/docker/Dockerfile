# Production-ready OpenEMR with pre-built assets
# Extends openemr/openemr:flex but builds during image creation instead of pod startup
# Result: Pod startup in 10-30 seconds instead of 10-15 minutes

FROM openemr/openemr:flex

# Copy OpenEMR source to /openemr (where flex entrypoint expects it with EASY_DEV_MODE_NEW=yes)
# The entrypoint will rsync this to /var/www/localhost/htdocs/openemr/
COPY --chown=www-data:www-data . /openemr/

# Run the build steps that normally happen on startup
# This is what the flex image does in its entrypoint, but we do it during build
RUN set -ex && \
    cd /openemr && \
    # Install Composer dependencies
    composer install --no-dev --optimize-autoloader && \
    # Install NPM dependencies
    npm install && \
    # Build assets (SCSS compilation, minification, etc.)
    npm run build && \
    # Optimize Composer autoloader
    composer dump-autoload -o && \
    # Clean up to reduce image size
    npm cache clean --force && \
    rm -rf /tmp/* /var/tmp/*

# Create CouchDB directories that the flex entrypoint expects when EASY_DEV_MODE_NEW=yes
RUN mkdir -p /couchdb/data /couchdb/original

# Set environment variables for flex entrypoint
# EASY_DEV_MODE_NEW=yes tells entrypoint to use code from /openemr instead of cloning from git
# FORCE_NO_BUILD_MODE=yes tells entrypoint to skip composer/npm build (already done)
ENV EASY_DEV_MODE_NEW=yes
ENV FORCE_NO_BUILD_MODE=yes

# Permissions will be handled by the base image's entrypoint
# The openemr/openemr:flex entrypoint sets up correct ownership on startup

# The rest (Apache config, PHP setup, environment handling, entrypoint)
# is inherited from openemr/openemr:flex

# Expose ports
EXPOSE 80 443

# Use the flex image's entrypoint (handles environment variables, database setup, etc.)
# But it will skip the build steps since assets are already built
