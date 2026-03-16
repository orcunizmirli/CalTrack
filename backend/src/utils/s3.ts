import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { config } from '../config';
import { randomUUID } from 'crypto';

const s3Client = new S3Client({
  region: config.aws.region,
  credentials: {
    accessKeyId: config.aws.accessKeyId,
    secretAccessKey: config.aws.secretAccessKey,
  },
});

/**
 * Upload a file buffer to S3 and return the public URL.
 * Organizes files by folder: ai-scans/, custom-foods/, etc.
 */
export async function uploadToS3(
  buffer: Buffer,
  folder: string,
  contentType: string,
  extension: string = 'jpg'
): Promise<string> {
  const key = `${folder}/${randomUUID()}.${extension}`;

  await s3Client.send(
    new PutObjectCommand({
      Bucket: config.aws.s3Bucket,
      Key: key,
      Body: buffer,
      ContentType: contentType,
    })
  );

  return `https://${config.aws.s3Bucket}.s3.${config.aws.region}.amazonaws.com/${key}`;
}
