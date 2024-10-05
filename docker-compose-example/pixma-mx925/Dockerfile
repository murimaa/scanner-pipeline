# Use the image built by your original Dockerfile as the base
FROM app-base

# Install additional packages
RUN apt install -y imagemagick ghostscript
RUN apt install -y sane sane-utils

ARG PRINTER_IP
RUN echo "bjnp://$PRINTER_IP" >> /etc/sane.d/pixma.conf

# Use sed to replace imagemagick PDF policy
RUN sed -i 's/<policy domain="coder" rights="none" pattern="PDF" \/>/<policy domain="coder" rights="read | write" pattern="PDF" \/>/' /etc/ImageMagick-6/policy.xml

# You can add any other customizations here

# Optionally, you can override the entrypoint or cmd if needed
# ENTRYPOINT ["/custom-entrypoint.sh"]
# CMD ["custom-start"]
