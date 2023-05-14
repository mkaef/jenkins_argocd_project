FROM python:3.11-slim-buster
RUN pip install flask
WORKDIR /app
COPY app.py .
EXPOSE 5000
ENTRYPOINT ["python", "app.py"]