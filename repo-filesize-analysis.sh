#!/bin/bash
# Save as /tmp/repo-filesize-analysis.sh
# Run with: 'sudo bash /tmp/repo-size-analysis.sh'

# Set thresholds in MB
SIZE_MAX_MB=400  # Looking for files over 400MB
SIZE_MIN_MB=100   # Looking for files between 100-400MB

# Convert MB to bytes for precise comparisons
SIZE_MAX_BYTES=$((SIZE_MAX_MB * 1024 * 1024))
SIZE_MIN_BYTES=$((SIZE_MIN_MB * 1024 * 1024))

# Initialize counters
repos_with_files_over_max=0
repos_with_files_between=0
repos_with_files_over_min=0
files_over_max=0
files_between=0

# Track repositories with specific file sizes
repos_over_max=""
repos_between=""

echo "Analyzing repositories in /data/user/repositories..."
echo "Total repository storage: $(sudo du -hsx /data/user/repositories/)"

# Get list of repositories
REPOS=$(sudo find /data/user/repositories -name "*.git" -type d)
TOTAL_REPOS=$(echo "$REPOS" | wc -l)

echo "Found $TOTAL_REPOS repositories to analyze"

# Create temporary files to store results
over_max_file="/tmp/repos_over_${SIZE_MAX_MB}mb.txt"
between_file="/tmp/repos_${SIZE_MIN_MB}mb_to_${SIZE_MAX_MB}mb.txt"
sudo touch $over_max_file $between_file
sudo chmod 666 $over_max_file $between_file
> $over_max_file
> $between_file

# Process each repository
for REPO in $REPOS; do
    REPO_NAME=$(echo "$REPO" | sed 's|/data/user/repositories/||g' | sed 's|\.git$||g')
    echo "Checking $REPO_NAME..."
    
    has_file_over_max=0
    has_file_between=0
    
    # Look for loose objects first (simpler for very small repos)
    # Run a simple find command to identify large files by size
    large_files=$(sudo find $REPO -type f -size +${SIZE_MIN_MB}M)
    
    if [ -n "$large_files" ]; then
        for file in $large_files; do
            size_bytes=$(sudo stat -c %s "$file" 2>/dev/null)
            if [ -n "$size_bytes" ] && [ "$size_bytes" -gt 0 ]; then
                size_mb=$((size_bytes / 1024 / 1024))
                file_path=$(echo "$file" | sed "s|$REPO/||")
                
                if [ "$size_bytes" -ge "$SIZE_MAX_BYTES" ]; then
                    echo "$REPO_NAME: $file_path ($size_mb MB)" >> $over_max_file
                    files_over_max=$((files_over_max + 1))
                    has_file_over_max=1
                elif [ "$size_bytes" -ge "$SIZE_MIN_BYTES" ]; then
                    echo "$REPO_NAME: $file_path ($size_mb MB)" >> $between_file
                    files_between=$((files_between + 1))
                    has_file_between=1
                fi
            fi
        done
    fi
    
    # If no large files found with direct approach, try git commands
    if [ $has_file_over_max -eq 0 ] && [ $has_file_between -eq 0 ]; then
        if [ -d "$REPO/objects/pack" ]; then
            cd $REPO
            # Check packed objects
            sudo git verify-pack -v objects/pack/pack-*.idx 2>/dev/null | 
            awk -v min_bytes=$SIZE_MIN_BYTES -v max_bytes=$SIZE_MAX_BYTES '
                $3 >= min_bytes {
                    print $1, $3
                }
            ' | while read hash size; do
                # Get filename for the object
                filename=$(sudo git rev-list --objects --all 2>/dev/null | 
                           grep $hash | awk '{print $2}')
                
                if [ -n "$filename" ]; then
                    size_mb=$((size / 1024 / 1024))
                    
                    if [ $size -ge $SIZE_MAX_BYTES ]; then
                        echo "$REPO_NAME: $filename ($size_mb MB)" >> $over_max_file
                        files_over_max=$((files_over_max + 1))
                        has_file_over_max=1
                    elif [ $size -ge $SIZE_MIN_BYTES ]; then
                        echo "$REPO_NAME: $filename ($size_mb MB)" >> $between_file
                        files_between=$((files_between + 1))
                        has_file_between=1
                    fi
                fi
            done
        fi
    fi
    
    # Update repository counters
    if [ $has_file_over_max -eq 1 ]; then
        repos_with_files_over_max=$((repos_with_files_over_max + 1))
        repos_with_files_over_min=$((repos_with_files_over_min + 1))
        repos_over_max="$repos_over_max $REPO_NAME"
    elif [ $has_file_between -eq 1 ]; then
        repos_with_files_between=$((repos_with_files_between + 1))
        repos_with_files_over_min=$((repos_with_files_over_min + 1)) 
        repos_between="$repos_between $REPO_NAME"
    fi
done

# Print summary report
echo "======================================"
echo "REPOSITORY FILE SIZE ANALYSIS SUMMARY"
echo "======================================"
echo "Total repositories analyzed: $TOTAL_REPOS"
echo ""
echo "1. How many repos have single files in excess of ${SIZE_MAX_MB}MB?"
echo "   Answer: $repos_with_files_over_max repositories"
if [ $repos_with_files_over_max -gt 0 ]; then
    echo "   Repositories: $(echo $repos_over_max | tr ' ' ',')"
fi
echo ""
echo "2. How many repos have files between ${SIZE_MIN_MB}MB to ${SIZE_MAX_MB}MB?"
echo "   Answer: $repos_with_files_between repositories"
if [ $repos_with_files_between -gt 0 ]; then
    echo "   Repositories: $(echo $repos_between | tr ' ' ',')"
fi
echo ""
echo "3. How many repos have files larger than ${SIZE_MIN_MB}MB?"
echo "   Answer: $repos_with_files_over_min repositories"
echo ""
echo "Total files over ${SIZE_MAX_MB}MB: $files_over_max"
echo "Total files between ${SIZE_MIN_MB}MB-${SIZE_MAX_MB}MB: $files_between"
echo ""
echo "Detailed report of files over ${SIZE_MAX_MB}MB: $over_max_file"
echo "Detailed report of files between ${SIZE_MIN_MB}MB-${SIZE_MAX_MB}MB: $between_file"
