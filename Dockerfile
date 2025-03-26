# Dockerfile.rails
FROM ruby:3.2

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  wget \
  curl \
  gnupg2 \
  bash

# Node.jsのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# Blenderのインストール
RUN wget https://mirror.clarkson.edu/blender/release/Blender3.4/blender-3.4.1-linux-x64.tar.xz \
    && tar -xf blender-3.4.1-linux-x64.tar.xz -C /opt \
    && rm blender-3.4.1-linux-x64.tar.xz

ENV PATH="/opt/blender-3.4.1-linux-x64:${PATH}"

WORKDIR /app

ENV BUNDLE_DEPLOYMENT=true
ENV BUNDLE_PATH=/gems

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json package-lock.json ./
RUN npm install

COPY . .

RUN npm run build

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]

EXPOSE 3000

CMD ["./bin/rails", "server"]
