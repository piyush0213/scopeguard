BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "room_member" (
    "id" bigserial PRIMARY KEY,
    "roomId" bigint NOT NULL,
    "name" text NOT NULL,
    "role" text NOT NULL,
    "color" bigint NOT NULL,
    "seat" bigint NOT NULL,
    "connections" bigint NOT NULL,
    "agreedRound" bigint NOT NULL,
    "joinedAt" timestamp without time zone NOT NULL,
    "token" text,
    "sgToken" text
);

-- Indexes
CREATE INDEX "room_member_room_idx" ON "room_member" USING btree ("roomId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "scope_agreement" (
    "id" bigserial PRIMARY KEY,
    "roomId" bigint NOT NULL,
    "orderId" text NOT NULL,
    "quoteVersion" bigint NOT NULL,
    "totalCents" bigint NOT NULL,
    "fingerprint" text NOT NULL,
    "signers" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "scope_agreement_order_idx" ON "scope_agreement" USING btree ("orderId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "scope_room" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "orderId" text NOT NULL,
    "title" text NOT NULL,
    "status" text NOT NULL,
    "hostMemberId" bigint,
    "round" bigint NOT NULL,
    "fingerprint" text,
    "momentAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "hostToken" text
);

-- Indexes
CREATE UNIQUE INDEX "scope_room_code_idx" ON "scope_room" USING btree ("code");


--
-- MIGRATION VERSION FOR scopeguard_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('scopeguard_app', '20261122013720934', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261122013720934', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();


COMMIT;
