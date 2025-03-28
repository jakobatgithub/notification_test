FROM python:3.13

# Set environment variables
ENV PYTHONUNBUFFERED=1 

# Copy the Django project files
COPY . /app
# Set the working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt
# COPY requirements-dev.txt /app/
# RUN pip install --no-cache-dir -r requirements-dev.txt

# Expose port 8000
EXPOSE 8000

# Serve static files
RUN mkdir -p /app/staticfiles

# Collect static files.
RUN python manage.py collectstatic --noinput --clear

# Command to run the application
# CMD ["gunicorn", "backend.wsgi:application", "--bind", "0.0.0.0:8000"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]