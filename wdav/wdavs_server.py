from wsgidav.wsgidav_app import WsgiDAVApp
from wsgidav.fs_dav_provider import FilesystemProvider
from cheroot import wsgi
import os

# Set the directory to serve
serve_directory = r"C:\Users\Admin\Desktop\wdav\files"

# Create directory if it doesn't exist
if not os.path.exists(serve_directory):
    os.makedirs(serve_directory)
    print(f"Created directory: {serve_directory}")

# Configure WebDAV provider
provider = FilesystemProvider(serve_directory)

app_config = {
    "provider_mapping": {"/": provider},
    "http_authenticator": {
        "accept_basic": True,
        "accept_digest": False,
        "default_to_digest": False,
    },
    "simple_dc": {"user_mapping": {"*": True}},  # Anonymous access
    "verbose": 1,
}

app = WsgiDAVApp(app_config)

# Start server
server_args = {
    "bind_addr": ("0.0.0.0", 9999),
    "wsgi_app": app,
}
server = wsgi.Server(**server_args)

print(f"WebDAV server starting on http://0.0.0.0:9999")
print(f"Serving directory: {serve_directory}")
print("Anonymous access enabled")
print("Press Ctrl+C to stop the server")

try:
    server.start()
except KeyboardInterrupt:
    print("\nShutting down server...")
    server.stop()
