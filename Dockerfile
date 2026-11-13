FROM python:3.14-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend ./backend
COPY frontend ./frontend
COPY manage.py .
RUN mkdir -p storage && python manage.py collectstatic --noinput && useradd --create-home fluxo && chown -R fluxo:fluxo /app
USER fluxo
EXPOSE 8000
CMD ["waitress-serve", "--listen=0.0.0.0:8000", "backend.wsgi:application"]
