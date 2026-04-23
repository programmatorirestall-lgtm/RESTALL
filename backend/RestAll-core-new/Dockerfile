FROM node:lts-alpine
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
EXPOSE 5236
CMD ["npm","run","start"]