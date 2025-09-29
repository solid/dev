FROM python:3-bookworm

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

CMD ["mkdocs", "serve"]

EXPOSE 8000
