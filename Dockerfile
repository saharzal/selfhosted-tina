# # # Use an official Node.js runtime as a base image
# # FROM node:14

# # # Set the working directory in the container
# # # WORKDIR /usr/src/app
# # WORKDIR /app

# # # Copy package.json and package-lock.json to the container
# # COPY package*.json ./

# # # Install app dependencies
# # RUN npm install

# # # Copy the local code to the container
# # COPY . .

# # # Expose the port your app runs on
# # EXPOSE 3000

# # # Define the command to run your app
# # # CMD ["npm", "start"]

# # CMD ["node", "./server.js"]
# FROM node:18.10.0-slim

# WORKDIR /app

# ENV NODE_ENV production
# ENV NEXT_TELEMETRY_DISABLED 1

# RUN addgroup --system --gid 1001 nodejs
# RUN adduser --system --uid 1001 nextjs

# COPY public ./public

# COPY next.config.js ./
# COPY package.json ./package.json
# # COPY --chown=nextjs:nodejs .next/standalone ./
# # COPY --chown=nextjs:nodejs .next/static ./.next/static
# # COPY node_modules/next/dist/compiled/jest-worker ./node_modules/next/dist/compiled/jest-worker

# RUN npm install
# RUN echo "Install Packages, End"

# RUN echo "Build, Start"
# RUN date +%T
# # Copy the local code to the container
# COPY . .

# RUN yarn run build

# RUN echo "Build, End"



# USER nextjs

# EXPOSE 3000

# ENV PORT 3000

# CMD ["node", "start"]

FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
# COPY node_modules ./node_modules

# RUN yarn 


# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
# COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED 1

RUN yarn build

# If using npm comment out above and use below instead
# RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000
# set hostname to localhost
# ENV HOSTNAME "0.0.0.0"

# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/next-config-js/output
CMD ["node", "server.js"]