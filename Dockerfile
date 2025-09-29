FROM python:3.14-rc-slim

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8000"]
