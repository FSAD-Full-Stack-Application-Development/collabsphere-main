FROM nginx:alpine

# Copy Flutter build output directly
COPY web/ /usr/share/nginx/html/

# Optional: custom nginx config if you need SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
