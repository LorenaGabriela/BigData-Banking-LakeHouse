Docker Explained --- BigData-Banking-LakeHouse
1. What is Docker?
Docker is a platform that lets you package an application together with
the environment it needs to run.

For example, a Python application may depend on: - a specific Python
version; - Java; - PySpark; - Delta Lake; - other Python or system
libraries.

Without Docker, you must install and configure these dependencies
directly on your computer. This can lead to problems when another
computer has different versions or configuration.

With Docker, you describe the environment once and run the application
inside a container. The container uses the environment packaged in a
Docker image.

The main benefit: the application runs in a predictable environment,
regardless of the developer's operating system, as long as Docker is
available.
2. The most important Docker concepts
2.1 Dockerfile
A Dockerfile is a text file containing instructions for building a
Docker image.

Think of it as a recipe: - choose a starting environment; - install the
required software; - copy the application files; - define the default
command.

Our project's Dockerfile:
FROM python:3.12-slim-bookworm

# Install Java 17, which Spark needs
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk-headless \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Configure Java
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Set the working directory inside the image
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the project files into the image
COPY . .

# Default command when the container starts
CMD ["python", "main.py"]
What each instruction means:
  Instruction                         Meaning
  FROM                              Selects the base image. We use a
lightweight Python 3.12 image based
on Debian Bookworm.

  RUN                               Executes a command while the image
is being built. Here, it installs
Java 17 and procps.

  ENV                               Defines environment variables
available inside the image and its
containers.

  WORKDIR                           Sets the working directory inside
the image.

  COPY                              Copies files from the build context
(your project) into the image.
CMD                               Defines the default command
executed when a container starts.
Important distinction: RUN happens during image building. CMD
happens when a container starts.
2.2 Docker image
A Docker image is the packaged template used to create containers.

In our project, this command builds the image:
docker compose build
Docker reads the Dockerfile, downloads the base image if necessary,
installs Java and Python dependencies, and copies the project files.

The result is an image that contains the environment needed by our
application.

An image is not the running application. It is the template from which
containers are created.
2.3 Docker container
A container is an instance of a Docker image.

For example:
docker compose up
creates and starts a container for our application.

The container runs the command configured in docker-compose.yml:
command: python main.py
When the Python process finishes, the container stops. This is normal
for a batch application: the container is not required to run forever.

You can list containers with:
docker ps
This shows running containers.

To also see stopped containers:
docker ps -a
2.4 Docker Compose
Docker Compose lets you define and run one or more related containers
using a YAML file.

Our docker-compose.yml:
services:
  banking-lakehouse:
    build: .
    container_name: banking-lakehouse
    volumes:
      - .:/app
    environment:
      JAVA_HOME: /usr/lib/jvm/java-17-openjdk-amd64
      PYTHONUNBUFFERED: "1"
    command: python main.py
Explanation:
  Setting                             Meaning
  services                          Defines the containers that make up
the application.

  banking-lakehouse                 The service name. We use it in
Compose commands.

  build: .                          Builds an image using the
Dockerfile in the current
directory.

  container_name                    Gives the container a readable
name.

  volumes                           Mounts a directory from the host
computer into the container.

  environment                       Defines environment variables
inside the container.
command                           Overrides the image's default
command for this Compose service.
Compose is especially useful when a project needs multiple services.
Later, our platform could use separate services for Spark, Kafka,
PostgreSQL, and other infrastructure.
2.5 Volume and bind mount
Our Compose file contains:
volumes:
  - .:/app
This is a bind mount.

It means: - . is the project directory on your Windows computer; -
/app is the directory inside the container; - Docker makes the host
directory available inside the container.

This is useful during development. When you edit main.py in IntelliJ
or PyCharm, the container sees the updated file without rebuilding the
image.

Important: a bind mount can hide files that were copied into /app
during image building. The mounted host directory takes precedence at
that location.

A Docker-managed volume is different: Docker manages its storage
location. Such volumes are commonly used to persist database data
independently of a container's lifecycle.
2.6 Environment variables
Environment variables provide configuration to an application without
hardcoding every setting.

For example:
environment:
  JAVA_HOME: /usr/lib/jvm/java-17-openjdk-amd64
  PYTHONUNBUFFERED: "1"
- JAVA_HOME tells Java-dependent tools where Java is installed.
- PYTHONUNBUFFERED=1 makes Python output appear immediately in
  container logs instead of waiting in an output buffer.
For real credentials, such as database passwords, do not commit secrets
to Git. Use environment variables supplied securely, a local .env file
excluded from Git, or a secrets manager.
3. How Docker works in our project
Our application needs Python, Java, PySpark, and Delta Lake.

The flow is:
1. We write Python code in the project.
2. The Dockerfile describes the environment.
3. Docker builds an image from the Dockerfile.
4. Docker Compose creates a container from that image.
5. The container executes python main.py.
6. PySpark starts a Spark session inside the container.
7. Our code creates and displays a DataFrame.
8. When the script finishes, the container exits.
A simplified picture:
Your computer
|
|-- Project files
|   |-- main.py
|   |-- requirements.txt
|   |-- Dockerfile
|   |-- docker-compose.yml
|
|-- Docker
    |
    |-- Image
    |   |-- Python 3.12
    |   |-- Java 17
    |   |-- PySpark
    |   |-- Delta Lake
    |
    |-- Container
        |
        |-- /app
        |-- python main.py
        |-- Spark application runs
4. Important Docker commands
Run these commands from the project directory, where
docker-compose.yml is located.
Build the image
docker compose build
Builds or rebuilds the image based on the Dockerfile.

Use it after changing the Dockerfile or dependencies in
requirements.txt. A source-code-only change normally does not require
a rebuild when the project is bind-mounted as in our configuration.
Start the application
docker compose up
Creates and starts the service container. It attaches the terminal to
the container's output.
Start in the background
docker compose up -d
The -d option means detached mode: the container runs in the
background.
Show running containers
docker ps
Show all containers, including stopped ones
docker ps -a
Display application logs
docker compose logs banking-lakehouse
Follow new log output continuously:
docker compose logs -f banking-lakehouse
Stop Compose services
docker compose down
Stops and removes the containers and the Compose network. It does not
normally remove named volumes.
Run a one-off container
docker compose run --rm banking-lakehouse
This creates a new container for the specified service, runs its
command, and removes that container when it finishes because of --rm.

We use this command to run our Spark application and avoid keeping a
stopped one-off container.
Open a shell inside a temporary service container
docker compose run --rm banking-lakehouse sh
This is useful for inspecting files and running commands inside the
Linux environment.

For example:
docker compose run --rm banking-lakehouse sh -lc "pwd && ls -la"
Rebuild and start
docker compose up --build
Builds the image if needed and then starts the services.
Remove unused Docker resources
docker system prune
This removes certain unused Docker resources. Read Docker's confirmation
prompt carefully before proceeding. Do not use aggressive cleanup
commands such as docker system prune -a --volumes unless you
understand what data and images may be deleted.
5. What is .dockerignore?
The .dockerignore file tells Docker which files and directories to
exclude from the build context when building an image.

Our file:
.venv/
venv/
.idea/
.git/
__pycache__/
*.pyc
*.pyo
.pytest_cache/
logs/
data/
Why do we need it?

Our local .venv can contain many files that are not needed inside the
image. Sending them to Docker would make the build context unnecessarily
large.

The .dockerignore file: - reduces the amount of data sent to the
Docker build process; - can make builds faster; - avoids copying local
virtual environments and Git metadata into the image.

Important: .dockerignore affects image building. It does not
automatically exclude these files from a bind mount such as .:/app.
6. Why are we using Docker for PySpark?
Running Spark directly on Windows can require additional Hadoop-related
configuration. In our case, Spark's filesystem operations encountered a
Windows winutils.exe issue.

Docker gives us a Linux environment with Java and Python installed in a
controlled way.

Our setup is:

  Component               Version / role
  Host operating system   Windows
Docker environment      Linux containers through Docker Desktop / WSL2
Python                  3.12
Java                    17
PySpark                 4.2.0
Delta Lake              4.4.1

This keeps the Spark runtime separate from the Python and Java
configuration installed directly on Windows.
7. Common problems and how to investigate them
Container exits with code 0
Exit code 0 means the main process finished successfully. It does not
necessarily mean the application performed the work you expected.

For example, defining a function without calling it will produce no
application output:
def main():
    print("Application started")
The function must be called:
if __name__ == "__main__":
    main()
Container exits with an error
Inspect the logs:
docker compose logs banking-lakehouse
Then inspect the container status:
docker compose ps -a
Changes to Python code are not visible
Check whether the bind mount is configured:
volumes:
  - .:/app
This makes the current host project directory visible inside /app.

If you changed a dependency or the Dockerfile, rebuild:
docker compose build
Docker cannot connect to the daemon
Make sure Docker Desktop is running, then check:
docker info
If Docker is working, this command displays information about both the
client and the server.
8. Docker concepts to remember for a technical interview
What is Docker?

Docker is a platform for packaging and running applications in isolated,
portable containers.

What is the difference between an image and a container?

An image is an immutable template used to create containers. A container
is a running or stopped instance of an image.

What is a Dockerfile?

A Dockerfile contains instructions for building an image, such as
selecting a base image, installing dependencies, copying files, and
defining a startup command.

What is Docker Compose?

Docker Compose is a tool for defining and running multi-container
applications using a YAML configuration file.

What is a volume?

A volume provides persistent storage managed by Docker. A bind mount
connects a specific host path to a path inside a container.

What is the difference between docker compose build and
docker compose up?

build creates or updates the image. up creates and starts the
service containers, building the image when required by the
configuration or when --build is used.

Why use Docker in a data engineering project?

It makes the development environment more reproducible and helps run
infrastructure consistently across different machines and environments.
9. Our project's current workflow
For normal development:
1. Edit Python code in the IDE.
2. Run the application:
   docker compose run --rm banking-lakehouse
3. Inspect the output.
4. Fix the code and run it again.
When changing dependencies or Docker configuration:
1. Update requirements.txt or the Dockerfile.
2. Rebuild:
   docker compose build
3. Run the application:
   docker compose run --rm banking-lakehouse
Remember: changing a Python file does not normally require
rebuilding our image because the project directory is bind-mounted into
the container. Changing installed dependencies does require rebuilding
the image.
10. A simple mental model
Remember these four definitions:
- Dockerfile = recipe for building the environment.
- Image = packaged template containing the environment.
- Container = instance created from the image.
- Docker Compose = configuration and command-line tool for running
  the services together.
For our Banking Lakehouse project, Docker provides the Linux-based
runtime in which Python, Java, PySpark, and Delta Lake work together.