#!/bin/sh

zip -r -o -X -ll google-services-firewall-cleaner_$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'build.sh' -x '.github/*'
