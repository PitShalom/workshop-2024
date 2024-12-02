# For Security Labs we need both the application and DB running within the same container.
# It's far easier to use the MariaDB base image and install Maven and Tomcat on top than
# the other way around. We are using Maven to enable re-compilation within the lab.
#
# https://hub.docker.com/_/mariadb/
# This is Ubuntu 20.04 LTS
FROM mariadb:10.6.2

# Configure MariaDB
ENV MYSQL_RANDOM_ROOT_PASSWORD=true
ENV MYSQL_DATABASE=blab

# Copy DB schema for DB initialisation
COPY db /docker-entrypoint-initdb.d

# Install OpenJDK 8, Maven, Node.js (for Snyk), and fortune game
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
RUN apt-get update \
    && apt-get -y install openjdk-8-jdk-headless openjdk-8-jre-headless maven fortune-mod iputils-ping curl \
    && curl -fsSL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs \
    && ln -s /usr/games/fortune /bin/ \
    && rm -rf /var/lib/apt/lists/*

# Install Snyk CLI globally
RUN npm install -g snyk

# Authenticate Snyk (Optional: Replace <your-snyk-token> with your token if desired)
# If token is not provided here, you can authenticate manually inside the container.

ARG SNYK_TOKEN

RUN snyk auth $SNYK_TOKEN

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

WORKDIR /app
COPY app /app
COPY maven-settings.xml /usr/share/maven/conf/settings.xml

# Compile
RUN mvn clean package && rm -rf target

# Optional: Run a Snyk test during the build process to validate dependencies
# Uncomment this if you want to fail the build if vulnerabilities are found.
# RUN snyk test || true

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-c"]
