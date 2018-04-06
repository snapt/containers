% SNAPT-ADC (1) Container Image Pages
% Snapt Inc <support@snapt.net>
% April 6, 2018

# NAME
snaptadc - SnaptADC (Application Delivery Controller) container image

# DESCRIPTION
Full SnaptADC as a stanalone Docker container. The SnaptADC container runs the full SnaptADC package including Balancer, Web Accelerator, Web Application Fireall and GSLB.

You can find more info about Snapt over at (http://snapt.net)

# USAGE
The SnaptADC image is designed to run on a redhat host running Docker.

To run the SnaptADC container run:

    # docker run -tdi -p 8080:8080 -p [range of ports you require] snaptadc/snaptredhat 

To remove the XYZ container from your system, run:

    # docker rm [container id]

Default user:root
Exposed ports:8080,29987
Volumes: ["/usr/local/snapt", "/etc/haproxy", "/etc/nginx", "/var", "/sys/fs/cgroup"]
Working directory:/
Default command:/usr/sbin/init
WebUI:Published on port 8080

-p 8080:8080
    Opens container port 8080 and maps it to the same port on the Host. This is used to expose the WebUI. Connect on hostip:8080

# SEE ALSO
Direct any technical queries to support@snapt.net or visit our Knowledge Base at https://support.snapt.net
