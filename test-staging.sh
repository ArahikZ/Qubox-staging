#!/usr/bin/expect -f
# qu_setup.expect
# Usage: expect qu_setup.expect /path/to/device.config

set timeout -1

# ------------- CONFIG HANDLING -------------

# Get config path from argv or default to ./device.config
set config [lindex $argv 0]
if {$config eq ""} {
    set config "./device.config"
}

# Read DEVICE_NAME from config file
set device_name ""
if {![file exists $config]} {
    puts "ERROR: Config file not found: $config"
    exit 1
}

set fp [open $config r]
while {[gets $fp line] >= 0} {
    # DEVICE_NAME=<value> (allow spaces around =)
    if {[regexp {^\s*DEVICE_NAME\s*=\s*(.+)\s*$} $line -> v]} {
        set device_name $v
    }
}
close $fp

if {$device_name eq ""} {
    puts "ERROR: DEVICE_NAME not found in $config"
    exit 1
}
puts "Using DEVICE_NAME from config: $device_name"

# ------------- DOCKER WAIT HELPER -------------

proc wait_for_dockers {min_count name_pattern} {
    while {1} {
        # Count containers
        set total_str [exec sh -c "docker ps -q | wc -l"]
        set total [string trim $total_str]

        # Get container names
        set names_output [exec sh -c "docker ps --format '{{.Names}}' 2>/dev/null || true"]
        set names [split $names_output "\n"]

        # Look for a container matching the pattern
        set have_match 0
        foreach n $names {
            if {$n eq ""} { continue }
            if {[string match $name_pattern $n]} {
                set have_match 1
                break
            }
        }

        puts "Docker status: $total containers, match=${have_match} (pattern: $name_pattern)"

        if {[string is integer -strict $total] && $total >= $min_count && $have_match} {
            puts "Docker requirement satisfied: $total containers and '$name_pattern' present."
            break
        }

        puts "Waiting for at least $min_count containers and '$name_pattern'..."
        sleep 5
    }
}

# ------------- STEP 1: DOWNLOAD SCRIPT -------------

puts "\n=== Downloading ecs-registration.sh ==="
spawn sudo curl --proto https -o ecs-registration.sh https://qu-releases.qubeyond.com/qubox/ecs-registration.sh
expect eof

# ------------- STEP 2: MAKE IT EXECUTABLE -------------

puts "\n=== chmod +x ecs-registration.sh ==="
spawn sudo chmod +x ecs-registration.sh
expect eof

# ------------- STEP 3: RUN ecs-registration.sh & ANSWER PROMPTS -------------

puts "\n=== Running ecs-registration.sh ==="
spawn sudo ./ecs-registration.sh

# Q1: Do you want to set a different device name? (y/n)
expect {
    -re {Do you want to set a different device name\? .*} {
        puts "Answering Y to: set different device name"
        send "Y\r"
    }
}

# Q2: Please enter a name to identify this device (may have trailing text)
expect {
    -re {Please enter a name to identify this device.*} {
        puts "Sending device name: $device_name"
        send "$device_name\r"
    }
}

# Purple screen popup that needs [enter]
expect {
    -re {Purple screen popup.*\[enter\]} {
        puts "Purple popup detected, sending Enter"
        send "\r"
    }
}

# Q3: Do you want to set a static ip address? (y/n)
expect {
    -re {Do you want to set a static ip address\? .*} {
        puts "Answering n to static IP question"
        send "n\r"
    }
}

# You can optionally wait for ecs-registration.sh to finish:
# (If it keeps running as a long-lived process, you may want to comment this out)
expect eof
puts "\n=== ecs-registration.sh completed (or detached) ==="

# ------------- STEP 4: WAIT FOR DOCKERS -------------

puts "\n=== Waiting for Docker stack to come up ==="
# Need: at least 10 containers AND one like ecs-qu-box-prod-xx-traefik-xx
wait_for_dockers 10 "ecs-qu-box-prod-*-traefik-*"

# ------------- STEP 5: RUN /home/qu/activate.sh AND CAPTURE GUID -------------

puts "\n=== Running /home/qu/activate.sh and looking for GUID ==="
# Run activate.sh from /home/qu
spawn bash -c "cd /home/qu && bash activate.sh"

# GUID pattern example: 66be-3c3a-5647-9387-c0c4-1890
# 6 groups of 4 alnum chars separated by '-'
# Regex: ([A-Za-z0-9]{4}(?:-[A-Za-z0-9]{4}){5})
set guid ""

expect {
    -re {([A-Za-z0-9]{4}(?:-[A-Za-z0-9]{4}){5})} {
        set guid $expect_out(1,string)
        puts "Captured GUID: $guid"
    }
    timeout {
        puts "Timed out waiting for GUID pattern."
    }
}

# Optionally wait for activate.sh to finish
expect eof

if {$guid eq ""} {
    puts "WARNING: No GUID captured."
} else {
    # Write GUID to a file (adjust path as needed)
    set guid_file "/home/qu/device_guid.txt"
    puts "Writing GUID to $guid_file"
    set gfp [open $guid_file "w"]
    puts $gfp $guid
    close $gfp
}

puts "\n=== Script finished up to GUID capture ==="
exit 0
