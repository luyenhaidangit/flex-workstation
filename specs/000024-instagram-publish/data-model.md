# Data Model & Interfaces: Instagram Publish

## 1. Local State Interface (Angular Component)

```typescript
export interface InstagramAuthConfig {
  appId: string;
  redirectUri: string;
  scope: string;
  accessToken?: string;
  instagramUserId?: string;
  username?: string;
}

export interface PublishPostDraft {
  mediaUrl: string;
  mediaType: 'IMAGE' | 'VIDEO';
  caption: string;
  mediaFile?: File;
}

export interface PublishLogEntry {
  id: string;
  timestamp: Date;
  type: 'INFO' | 'SUCCESS' | 'ERROR';
  action: string;
  details: string | object;
}

export interface InstagramPublishState {
  auth: InstagramAuthConfig;
  draft: PublishPostDraft;
  isPublishing: boolean;
  isLoggingIn: boolean;
  logs: PublishLogEntry[];
  mode: 'MOCK' | 'LIVE';
}
```

## 2. Instagram API Payload Contracts

### Container Creation Request (`POST /v19.0/{ig-user-id}/media`)
```json
{
  "image_url": "https://example.com/image.jpg",
  "caption": "Hello Instagram! #test #flex",
  "access_token": "IGAA..."
}
```

### Container Status Query (`GET /v19.0/{container-id}?fields=status_code`)
```json
{
  "status_code": "FINISHED",
  "id": "17841400000000000"
}
```

### Media Publish Request (`POST /v19.0/{ig-user-id}/media_publish`)
```json
{
  "creation_id": "17841400000000000",
  "access_token": "IGAA..."
}
```
