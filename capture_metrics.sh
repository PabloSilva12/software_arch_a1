#!/bin/bash
# Capture Docker stats periodically

output_file="metrics.txt"
duration=300  # Test duration in seconds (5 minutes)
interval=1    # Capture interval in seconds

end=$((SECONDS + duration))

echo "Capturing Docker stats for $duration seconds..."

while [ $SECONDS -lt $end ]; do
  echo "------ $(date) ------" >> $output_file
  docker stats --no-stream >> $output_file
  sleep $interval
done

echo "Metrics capture complete."
