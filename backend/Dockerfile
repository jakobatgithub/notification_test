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

# Copy and use the entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose port 8000
EXPOSE 8000

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]

# Final command (passed to entrypoint)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]