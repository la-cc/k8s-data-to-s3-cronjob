#!/bin/sh

# Function to zip and encrypt a file
encrypt_file() {
    local file_to_encrypt="$1"
    local encryption_key="$2"
    # Zip and encrypt the file
    7z a -tzip -p"$encryption_key" -mem=AES256 "${file_to_encrypt}.zip" "$file_to_encrypt"
    if [ $? -eq 0 ]; then
        echo "Zip and encryption successful: ${file_to_encrypt}.zip"
        # Optionally, remove the original file to save space
        rm "$file_to_encrypt"
    else
        echo "Error during zip and encryption of: ${file_to_encrypt}"
    fi
}

# Function to set the AWS configuration
init_aws_config() {
    # Set the AWS credentials
    aws configure set aws_access_key_id "$AWS_S3_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_S3_SECRET_ACCESS_KEY"
}

# Function to create a backup of each directory
backup_directories() {
    OLD_IFS="$IFS"
    IFS=','
    for directory_path in $DIRECTORY_PATH; do
        echo "Backing up directory: $directory_path"
        # Define the filename for the backup
        backup_file="${PWD}/backup_$(basename "$directory_path")_$(date +%Y-%m-%d).tar.gz"
        # Check if directory exists before attempting backup
        if [ -d "$directory_path" ]; then
            # Create the backup of the entire directory
            tar -czf "$backup_file" -C "$directory_path" .
            if [ $? -eq 0 ]; then
                echo "Backup successful: $(basename "$directory_path")"
                # Call encrypt_file function to encrypt the backup file
                encrypt_file "$backup_file" "$ENCRYPTION_KEY"
            else
                echo "Error during backup of: $(basename "$directory_path")"
                rm "$backup_file"
            fi
        else
            echo "Directory does not exist: $directory_path"
        fi
    done
    IFS="$OLD_IFS"
}

# Function to create a backup of each file from a list of file paths
backup_files() {
    OLD_IFS="$IFS"
    IFS=','
    for file_path in $FILE_PATH; do
        echo "Backing up file: $file_path"
        # Define the filename for the backup
        backup_file="${PWD}/backup_$(basename "$file_path")_$(date +%Y-%m-%d).tar.gz"
        # Check if file exists before attempting backup
        if [ -f "$file_path" ]; then
            # Create the backup
            tar -czf "$backup_file" "$file_path"
            if [ $? -eq 0 ]; then
                echo "Backup successful: $(basename "$file_path")"
                # Call encrypt_file function to encrypt the backup file
                encrypt_file "$backup_file" "$ENCRYPTION_KEY"
            else
                echo "Error during backup of: $(basename "$file_path")"
            fi
        else
            echo "File does not exist: $file_path"
        fi
    done
    IFS="$OLD_IFS"
}

# New function to upload encrypted files
upload_encrypted_files() {
    for file in *.zip; do
        echo "Uploading: $file"
        aws s3 cp "$file" "s3://${AWS_S3_BUCKET}/$file" --endpoint-url "$AWS_S3_ENDPOINT_URL"
        if [ $? -eq 0 ]; then
            echo "Upload successful: $file"
            # Optionally, remove the local file to save space
            rm "$file"
            # Check if ENABLE_WEBHOOK_ENDPOINT is set to true before calling push_to_webhook_endpoint
            if [ "$ENABLE_WEBHOOK_ENDPOINT" = "true" ]; then
                # Call push_to_webhook_endpoint function to notify the webhook about the upload
                push_to_webhook_endpoint "$file"
            fi
        else
            echo "Error during upload of: $file"
        fi
    done
}

push_to_webhook_endpoint() {
    local uploaded_file="$1"
    echo "Notifying webhook about the upload of: $uploaded_file"
    # use curl to send a POST request to the webhook endpoint
    curl -X POST -H "Content-Type: application/json" \
        -d "{
        \"filename\": \"$uploaded_file\",
        \"status\": \"uploaded\",
        \"summary\": \"Backup file uploaded successfully\",
        \"text\": \"The backup file $uploaded_file has been successfully uploaded.\"
        }" "$WEBHOOK_ENDPOINT"
    if [ $? -eq 0 ]; then
        echo "Webhook notification successful for: $uploaded_file"
    else
        echo "Error during webhook notification for: $uploaded_file"
    fi
}

main() {
    # Set the AWS configuration
    init_aws_config

    # Check if FILE_PATH variable is not empty
    if [ -n "$FILE_PATH" ]; then
        # Create a backup for one or multiple files
        backup_files
    else
        echo "FILE_PATH is empty, skipping file backup."
    fi

    # Check if DIRECTORY_PATH variable is not empty
    if [ -n "$DIRECTORY_PATH" ]; then
        # Create a backup for one or multiple directories
        backup_directories
    else
        echo "DIRECTORY_PATH is empty, skipping directory backup."
    fi

    # Upload the encrypted files to S3
    upload_encrypted_files
}

main
