--
-- PostgreSQL database dump
--

\restrict knntWpzktnDbhKEcaJGFIk1G8gFhH8wXanexSNbhnCNfaRAQkS18kg3Ojf74nIj

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: application_status; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.application_status AS ENUM (
    'PENDING',
    'FIT_CALL_SCHEDULED',
    'APPROVED',
    'REJECTED',
    'WAITLISTED'
);


ALTER TYPE public.application_status OWNER TO pbn_user;

--
-- Name: coupon_status; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.coupon_status AS ENUM (
    'ACTIVE',
    'USED',
    'EXPIRED'
);


ALTER TYPE public.coupon_status OWNER TO pbn_user;

--
-- Name: event_type; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.event_type AS ENUM (
    'FLAGSHIP',
    'VIRTUAL',
    'MICRO_MEETUP'
);


ALTER TYPE public.event_type OWNER TO pbn_user;

--
-- Name: membership_type; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.membership_type AS ENUM (
    'CHARTER',
    'STANDARD'
);


ALTER TYPE public.membership_type OWNER TO pbn_user;

--
-- Name: offer_type; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.offer_type AS ENUM (
    'DISCOUNT',
    'FREE_ITEM',
    'SERVICE'
);


ALTER TYPE public.offer_type OWNER TO pbn_user;

--
-- Name: payment_status; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.payment_status AS ENUM (
    'PENDING',
    'COMPLETED',
    'FAILED',
    'REFUNDED'
);


ALTER TYPE public.payment_status OWNER TO pbn_user;

--
-- Name: payment_type; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.payment_type AS ENUM (
    'MEMBERSHIP',
    'MEETING_FEE',
    'RENEWAL'
);


ALTER TYPE public.payment_type OWNER TO pbn_user;

--
-- Name: referral_status; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.referral_status AS ENUM (
    'submitted',
    'contacted',
    'meeting_scheduled',
    'closed_won',
    'closed_lost',
    'negotiation',
    'in_progress',
    'success'
);


ALTER TYPE public.referral_status OWNER TO pbn_user;

--
-- Name: rsvp_status; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.rsvp_status AS ENUM (
    'GOING',
    'NOT_GOING',
    'MAYBE'
);


ALTER TYPE public.rsvp_status OWNER TO pbn_user;

--
-- Name: token_status; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.token_status AS ENUM (
    'PENDING',
    'CONFIRMED',
    'EXPIRED',
    'CANCELLED'
);


ALTER TYPE public.token_status OWNER TO pbn_user;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: pbn_user
--

CREATE TYPE public.user_role AS ENUM (
    'PROSPECT',
    'MEMBER',
    'CHAPTER_ADMIN',
    'SUPER_ADMIN',
    'PARTNER_ADMIN'
);


ALTER TYPE public.user_role OWNER TO pbn_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO pbn_user;

--
-- Name: application_status_history; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.application_status_history (
    application_id uuid NOT NULL,
    old_status character varying(30) NOT NULL,
    new_status character varying(30) NOT NULL,
    changed_by_user_id uuid,
    notes text,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.application_status_history OWNER TO pbn_user;

--
-- Name: applications; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.applications (
    full_name character varying(150) NOT NULL,
    business_name character varying(255) NOT NULL,
    contact_number character varying(20) NOT NULL,
    email character varying(255),
    district character varying(100),
    industry_category_id uuid NOT NULL,
    status public.application_status NOT NULL,
    fit_call_date timestamp with time zone,
    notes text,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.applications OWNER TO pbn_user;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.audit_logs (
    actor_id uuid,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    action character varying(50) NOT NULL,
    old_value jsonb,
    new_value jsonb,
    ip_address character varying(45),
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO pbn_user;

--
-- Name: businesses; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.businesses (
    owner_user_id uuid NOT NULL,
    business_name character varying(255) NOT NULL,
    industry_category_id uuid NOT NULL,
    district character varying(100),
    description text,
    website character varying(500),
    logo_url character varying(500),
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.businesses OWNER TO pbn_user;

--
-- Name: chapter_memberships; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.chapter_memberships (
    user_id uuid NOT NULL,
    chapter_id uuid NOT NULL,
    industry_category_id uuid NOT NULL,
    membership_type public.membership_type NOT NULL,
    start_date date NOT NULL,
    end_date date,
    is_active boolean NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chapter_memberships OWNER TO pbn_user;

--
-- Name: chapters; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.chapters (
    name character varying(150) NOT NULL,
    description text,
    meeting_schedule character varying(255),
    is_active boolean NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.chapters OWNER TO pbn_user;

--
-- Name: coupon_codes; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.coupon_codes (
    offer_id uuid NOT NULL,
    user_id uuid NOT NULL,
    code character varying(20) NOT NULL,
    status public.coupon_status NOT NULL,
    used_at timestamp with time zone,
    expires_at timestamp with time zone NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.coupon_codes OWNER TO pbn_user;

--
-- Name: event_attendance; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.event_attendance (
    event_id uuid NOT NULL,
    user_id uuid NOT NULL,
    marked_at timestamp with time zone NOT NULL,
    marked_by uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.event_attendance OWNER TO pbn_user;

--
-- Name: event_rsvps; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.event_rsvps (
    event_id uuid NOT NULL,
    user_id uuid NOT NULL,
    status public.rsvp_status NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.event_rsvps OWNER TO pbn_user;

--
-- Name: events; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.events (
    chapter_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    event_type public.event_type NOT NULL,
    location character varying(500),
    meeting_link character varying(500),
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone NOT NULL,
    fee numeric(10,2) NOT NULL,
    max_attendees integer,
    is_published boolean NOT NULL,
    is_active boolean NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.events OWNER TO pbn_user;

--
-- Name: industry_categories; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.industry_categories (
    name character varying(150) NOT NULL,
    slug character varying(150) NOT NULL,
    description text,
    is_active boolean NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.industry_categories OWNER TO pbn_user;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.notifications (
    user_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    body text NOT NULL,
    notification_type character varying(50) NOT NULL,
    data jsonb,
    is_read boolean NOT NULL,
    sent_at timestamp with time zone NOT NULL,
    read_at timestamp with time zone,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notifications OWNER TO pbn_user;

--
-- Name: offer_redemptions; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.offer_redemptions (
    offer_id uuid NOT NULL,
    user_id uuid NOT NULL,
    redeemed_at timestamp with time zone NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    redemption_token_id uuid
);


ALTER TABLE public.offer_redemptions OWNER TO pbn_user;

--
-- Name: offers; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.offers (
    partner_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    offer_type public.offer_type NOT NULL,
    discount_percentage integer,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean NOT NULL,
    redemption_instructions text,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.offers OWNER TO pbn_user;

--
-- Name: partners; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.partners (
    name character varying(255) NOT NULL,
    logo_url character varying(500),
    description text,
    website character varying(500),
    is_active boolean NOT NULL,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    admin_id uuid
);


ALTER TABLE public.partners OWNER TO pbn_user;

--
-- Name: payments; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.payments (
    user_id uuid NOT NULL,
    amount numeric(12,2) NOT NULL,
    currency character varying(10) NOT NULL,
    payment_type public.payment_type NOT NULL,
    reference_id character varying(255),
    gateway_reference character varying(255),
    status public.payment_status NOT NULL,
    gateway_response jsonb,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.payments OWNER TO pbn_user;

--
-- Name: privilege_cards; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.privilege_cards (
    user_id uuid NOT NULL,
    card_number character varying(50) NOT NULL,
    qr_code_data text,
    is_active boolean NOT NULL,
    issued_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.privilege_cards OWNER TO pbn_user;

--
-- Name: redemption_tokens; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.redemption_tokens (
    offer_id uuid NOT NULL,
    user_id uuid NOT NULL,
    token uuid NOT NULL,
    status public.token_status NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    signer_name character varying(255),
    signature_data text,
    confirmed_at timestamp with time zone,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.redemption_tokens OWNER TO pbn_user;

--
-- Name: referral_status_history; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.referral_status_history (
    referral_id uuid NOT NULL,
    old_status character varying(30) NOT NULL,
    new_status character varying(30) NOT NULL,
    notes text,
    changed_by uuid,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.referral_status_history OWNER TO pbn_user;

--
-- Name: referrals; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.referrals (
    from_member_id uuid NOT NULL,
    to_member_id uuid NOT NULL,
    client_name character varying(150) NOT NULL,
    client_phone character varying(20),
    client_email character varying(255),
    description text,
    estimated_value numeric(14,2),
    actual_value numeric(14,2),
    status public.referral_status NOT NULL,
    closed_at timestamp with time zone,
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT no_self_referral CHECK ((from_member_id <> to_member_id))
);


ALTER TABLE public.referrals OWNER TO pbn_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: pbn_user
--

CREATE TABLE public.users (
    phone_number character varying(20) NOT NULL,
    email character varying(255),
    full_name character varying(150) NOT NULL,
    role public.user_role NOT NULL,
    is_active boolean NOT NULL,
    fcm_token character varying(500),
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    password_hash character varying(255) DEFAULT NULL::character varying
);


ALTER TABLE public.users OWNER TO pbn_user;

--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.alembic_version (version_num) FROM stdin;
75ef26f3d9e9
\.


--
-- Data for Name: application_status_history; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.application_status_history (application_id, old_status, new_status, changed_by_user_id, notes, id, created_at, updated_at) FROM stdin;
4db34db5-f573-484a-a40b-4acae78dfedd		pending	\N	Application submitted	3e7977de-64b6-41da-8417-2f42985f6ab0	2026-04-02 12:31:24.007015+05:30	2026-04-02 12:31:24.007015+05:30
4db34db5-f573-484a-a40b-4acae78dfedd	pending	fit_call_scheduled	a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	\N	983fc697-86df-4e96-93d7-13c686da7556	2026-04-02 12:31:28.393834+05:30	2026-04-02 12:31:28.393834+05:30
d5f1b0a6-0041-41df-bac9-bdcb22844fe0		pending	\N	Application submitted	68eee93f-3cfc-4baa-90cb-cf1f15a86ad6	2026-04-02 12:33:05.945485+05:30	2026-04-02 12:33:05.945485+05:30
d5f1b0a6-0041-41df-bac9-bdcb22844fe0	pending	fit_call_scheduled	a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	\N	d01eef5e-a330-494b-8267-43e54e3bb331	2026-04-02 12:33:10.047948+05:30	2026-04-02 12:33:10.047948+05:30
7e758ce0-5af2-4f30-b662-6ff1a1bffdcd		pending	\N	Application submitted	5a769d86-b683-4dce-9935-f7925930a9a9	2026-04-02 12:36:54.683362+05:30	2026-04-02 12:36:54.683362+05:30
7e758ce0-5af2-4f30-b662-6ff1a1bffdcd	pending	fit_call_scheduled	a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	\N	fedf5033-4c42-482d-9665-6f896962f713	2026-04-02 12:36:58.802165+05:30	2026-04-02 12:36:58.802165+05:30
7e758ce0-5af2-4f30-b662-6ff1a1bffdcd	fit_call_scheduled	approved	a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	\N	e6cafe8c-f3a8-43ee-b295-15eff8c197fc	2026-04-02 12:37:02.910769+05:30	2026-04-02 12:37:02.910769+05:30
32a55b39-088d-4907-a64e-70612fa135ac		pending	\N	Application submitted	d2cf6eab-247e-496d-b24a-4be6391eef33	2026-04-02 12:37:33.258568+05:30	2026-04-02 12:37:33.258568+05:30
32a55b39-088d-4907-a64e-70612fa135ac	pending	fit_call_scheduled	a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	\N	0fbcaffa-67dc-4a2e-ad4f-554434d9ca49	2026-04-02 12:37:37.380643+05:30	2026-04-02 12:37:37.380643+05:30
06f14770-3836-40d0-9ab0-5a637ab00a58		pending	\N	Application submitted	e8ca4248-ddd6-475a-bcda-bc1462092c1f	2026-04-02 12:38:39.443447+05:30	2026-04-02 12:38:39.443447+05:30
06f14770-3836-40d0-9ab0-5a637ab00a58	pending	fit_call_scheduled	a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	\N	05bd35f2-688b-4c08-a932-7300dc453d6c	2026-04-02 12:38:43.858195+05:30	2026-04-02 12:38:43.858195+05:30
06f14770-3836-40d0-9ab0-5a637ab00a58	fit_call_scheduled	approved	a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	\N	fc983ce0-ee3b-4472-b014-9921cd00d2ac	2026-04-02 12:38:50.58877+05:30	2026-04-02 12:38:50.58877+05:30
5daed4b7-324e-4fc8-97e7-09606544f53a		pending	\N	Application submitted	f5a40854-e064-479d-bb91-641b04b482e2	2026-04-04 10:47:20.423519+05:30	2026-04-04 10:47:20.423519+05:30
5daed4b7-324e-4fc8-97e7-09606544f53a	pending	fit_call_scheduled	15c59f4c-0e12-4451-9bed-6edfe7109429	\N	67ee2413-12ca-4390-b14e-e181351db9f1	2026-04-04 11:45:11.297064+05:30	2026-04-04 11:45:11.297064+05:30
6c43e18a-e24a-42cd-bb54-c656823b1c32		pending	\N	Application submitted	1ff5f7b0-999a-4bce-bacf-764b6ad5332d	2026-04-07 11:10:53.623055+05:30	2026-04-07 11:10:53.623055+05:30
6c43e18a-e24a-42cd-bb54-c656823b1c32	pending	fit_call_scheduled	1f31b86e-5ada-4b13-bed2-e9b3c3d350da	\N	c431ec3b-bf4d-408d-87e5-3cc9b082e245	2026-04-07 11:18:59.963339+05:30	2026-04-07 11:18:59.963339+05:30
6c43e18a-e24a-42cd-bb54-c656823b1c32	fit_call_scheduled	waitlisted	1f31b86e-5ada-4b13-bed2-e9b3c3d350da	\N	52f3c4b5-99fe-4c92-9107-98797bd95875	2026-04-07 11:19:10.260861+05:30	2026-04-07 11:19:10.260861+05:30
6c43e18a-e24a-42cd-bb54-c656823b1c32	waitlisted	approved	1f31b86e-5ada-4b13-bed2-e9b3c3d350da	\N	717db83e-39e5-4e3d-85f7-46b15a27bd5d	2026-04-07 11:19:19.56823+05:30	2026-04-07 11:19:19.56823+05:30
8a7ded0b-a188-4cd2-9c9f-138e0d1bb4ce		pending	\N	Application submitted	543b7ad0-4628-4ef8-ada9-9f13268983f5	2026-04-07 11:21:12.241327+05:30	2026-04-07 11:21:12.241327+05:30
\.


--
-- Data for Name: applications; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.applications (full_name, business_name, contact_number, email, district, industry_category_id, status, fit_call_date, notes, id, created_at, updated_at) FROM stdin;
Kamal Perera	KP Solutions	+94771234567	kamal@kp.lk	Colombo	5400bbcc-e1f0-4552-ab12-ea9691f705e2	FIT_CALL_SCHEDULED	\N	\N	4db34db5-f573-484a-a40b-4acae78dfedd	2026-04-02 12:31:24.007015+05:30	2026-04-02 12:31:28.400574+05:30
Kamal Perera	KP Solutions	+94777643694	kamal@kp.lk	Colombo	5400bbcc-e1f0-4552-ab12-ea9691f705e2	FIT_CALL_SCHEDULED	\N	\N	d5f1b0a6-0041-41df-bac9-bdcb22844fe0	2026-04-02 12:33:05.945485+05:30	2026-04-02 12:33:10.055024+05:30
Kamal Perera	KP Solutions	+94773761046	kamal@kp.lk	Colombo	5d44d98d-1168-4c1c-884d-e7a6bdda7a4e	APPROVED	\N	\N	7e758ce0-5af2-4f30-b662-6ff1a1bffdcd	2026-04-02 12:36:54.683362+05:30	2026-04-02 12:37:02.91491+05:30
Kamal Perera	KP Solutions	+94776741847	kamal@kp.lk	Colombo	5d44d98d-1168-4c1c-884d-e7a6bdda7a4e	FIT_CALL_SCHEDULED	\N	\N	32a55b39-088d-4907-a64e-70612fa135ac	2026-04-02 12:37:33.258568+05:30	2026-04-02 12:37:37.389845+05:30
Kamal Perera	KP Solutions	+94773632973	kamal@kp.lk	Colombo	7e18de53-ba51-432d-a955-d086b4cf2511	APPROVED	\N	\N	06f14770-3836-40d0-9ab0-5a637ab00a58	2026-04-02 12:38:39.443447+05:30	2026-04-02 12:38:50.592751+05:30
Mohamed Musni	Mcube	+94756371472	musnymohammed@gmail.com	Colombo	5d44d98d-1168-4c1c-884d-e7a6bdda7a4e	FIT_CALL_SCHEDULED	\N	\N	5daed4b7-324e-4fc8-97e7-09606544f53a	2026-04-04 10:47:20.423519+05:30	2026-04-04 11:45:11.302634+05:30
Ruwan Gamage	Gamage Motors	+94773001001	ruwan@gmail.com	Colombo	13538228-dcec-4753-8f4a-24c4a3f2c08d	PENDING	\N	Referred by Ashan Fernando	ea7038f6-366b-41bd-8a4d-532377a55587	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Nimali Jayasuriya	Nimali's Kitchen	+94773001002	nimali@gmail.com	Kandy	7e18de53-ba51-432d-a955-d086b4cf2511	PENDING	\N	Interested in hospitality network	a65289c8-1dd1-44c6-a331-1d108a95ce68	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Tharaka Weerasinghe	BuildMaster Eng.	+94773001003	tharaka@gmail.com	Galle	226503f1-1ab8-41c9-83e4-5f0a5917afb2	FIT_CALL_SCHEDULED	2026-04-06 07:38:16.343367+05:30	Scheduled fit call with chapter lead	16d06744-be3b-43e3-b7d8-288b4c1491a9	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Ruwan Gamage	Gamage Motors	+94773001001	ruwan@gmail.com	Colombo	13538228-dcec-4753-8f4a-24c4a3f2c08d	PENDING	\N	Referred by Ashan Fernando	e1e4c915-7b51-4608-8da5-4e5b90d366b0	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
Nimali Jayasuriya	Nimali's Kitchen	+94773001002	nimali@gmail.com	Kandy	7e18de53-ba51-432d-a955-d086b4cf2511	PENDING	\N	Interested in hospitality network	a3a04e00-2fe6-4eb2-9f04-8c4d3285b928	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
Tharaka Weerasinghe	BuildMaster Eng.	+94773001003	tharaka@gmail.com	Galle	226503f1-1ab8-41c9-83e4-5f0a5917afb2	FIT_CALL_SCHEDULED	2026-04-06 07:38:28.932648+05:30	Scheduled fit call with chapter lead	e4228928-d6cc-4171-968b-b58d7fe623ba	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
Musni	Hashante	+94771234567	musny@gmail.com	Trincomalee	1b93f9c6-5558-4042-9c9c-7aca5420c489	APPROVED	\N	\N	6c43e18a-e24a-42cd-bb54-c656823b1c32	2026-04-07 11:10:53.623055+05:30	2026-04-07 11:19:19.575034+05:30
Sinthujan	Hashante	+94775656587	sinthujan@gmail.com	Trincomalee	37513415-22e2-4ae6-b46d-5cc99218422b	PENDING	\N	\N	8a7ded0b-a188-4cd2-9c9f-138e0d1bb4ce	2026-04-07 11:21:12.241327+05:30	2026-04-07 11:21:12.241327+05:30
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.audit_logs (actor_id, entity_type, entity_id, action, old_value, new_value, ip_address, id, created_at, updated_at) FROM stdin;
a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	application	4db34db5-f573-484a-a40b-4acae78dfedd	status_update	{"status": "pending"}	{"status": "fit_call_scheduled"}	\N	851b706c-5a17-4e66-952f-24b124358a2f	2026-04-02 12:31:28.393834+05:30	2026-04-02 12:31:28.393834+05:30
a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	application	d5f1b0a6-0041-41df-bac9-bdcb22844fe0	status_update	{"status": "pending"}	{"status": "fit_call_scheduled"}	\N	07131c41-61d3-4785-bf8f-d7f6b852600a	2026-04-02 12:33:10.047948+05:30	2026-04-02 12:33:10.047948+05:30
a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	application	7e758ce0-5af2-4f30-b662-6ff1a1bffdcd	status_update	{"status": "pending"}	{"status": "fit_call_scheduled"}	\N	9b91dbec-421c-42aa-a4fc-bd76f780ac6d	2026-04-02 12:36:58.802165+05:30	2026-04-02 12:36:58.802165+05:30
a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	application	7e758ce0-5af2-4f30-b662-6ff1a1bffdcd	status_update	{"status": "fit_call_scheduled"}	{"status": "approved"}	\N	96d9c05f-818c-43be-9668-abfcc1db4dcb	2026-04-02 12:37:02.910769+05:30	2026-04-02 12:37:02.910769+05:30
a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	application	32a55b39-088d-4907-a64e-70612fa135ac	status_update	{"status": "pending"}	{"status": "fit_call_scheduled"}	\N	04041256-0724-4c61-baaa-f70c157ac612	2026-04-02 12:37:37.380643+05:30	2026-04-02 12:37:37.380643+05:30
a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	application	06f14770-3836-40d0-9ab0-5a637ab00a58	status_update	{"status": "pending"}	{"status": "fit_call_scheduled"}	\N	78ee40f8-6f95-4d0b-b717-472721a47a5d	2026-04-02 12:38:43.858195+05:30	2026-04-02 12:38:43.858195+05:30
a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	application	06f14770-3836-40d0-9ab0-5a637ab00a58	status_update	{"status": "fit_call_scheduled"}	{"status": "approved"}	\N	72fd5365-1c84-4556-9e73-b5a6791803ed	2026-04-02 12:38:50.58877+05:30	2026-04-02 12:38:50.58877+05:30
a563e74e-3ce3-4a8a-86d3-6b6b707dcd9a	chapter_membership	0781fe19-2406-4e0d-a530-903e1320bb02	delete	{"user_id": "a563e74e-3ce3-4a8a-86d3-6b6b707dcd9a", "industry": "0572680b-feba-4341-9e10-d0d8fd177be3", "chapter_id": "580c5d0a-714f-49a1-a4e7-afddcddc6993"}	\N	\N	e57fabce-0ba0-420e-a226-332572a083b5	2026-04-02 12:42:40.54032+05:30	2026-04-02 12:42:40.54032+05:30
\N	payment	b2f276ed-0c5a-4979-aa7b-e4fc3b43f83f	webhook_processed	{"status": "pending"}	{"status": "completed"}	\N	6ca8ef50-87fe-407b-b018-c4cc4dbe4212	2026-04-02 14:33:58.257318+05:30	2026-04-02 14:33:58.257318+05:30
97487004-06f4-435c-8959-8f661040a723	user	94934609-c4da-4db8-a98c-700015a4ee9b	test_seed	{"note": "before"}	{"note": "after"}	\N	3b94f4bb-9326-49c9-b919-ef1fa2314e0b	2026-04-02 16:45:52.982026+05:30	2026-04-02 16:45:52.982026+05:30
d277b254-ffc3-4399-84fc-95fa2ea9bd7a	user	b6e4728c-9740-4912-9321-e2f36eaf1c64	test_seed	{"note": "before"}	{"note": "after"}	\N	b204291e-c4e9-4286-8d10-8665662b98ed	2026-04-02 16:47:41.452366+05:30	2026-04-02 16:47:41.452366+05:30
d277b254-ffc3-4399-84fc-95fa2ea9bd7a	user	b6e4728c-9740-4912-9321-e2f36eaf1c64	deactivate	{"is_active": true}	{"is_active": false}	\N	b154166f-b565-4917-95e0-ee24e75f2eb6	2026-04-02 16:48:02.738406+05:30	2026-04-02 16:48:02.738406+05:30
d277b254-ffc3-4399-84fc-95fa2ea9bd7a	user	b6e4728c-9740-4912-9321-e2f36eaf1c64	reactivate	{"is_active": false}	{"is_active": true}	\N	9a7e21f0-5db3-4e68-b3b3-6e8436933052	2026-04-02 16:48:04.819949+05:30	2026-04-02 16:48:04.819949+05:30
15c59f4c-0e12-4451-9bed-6edfe7109429	application	5daed4b7-324e-4fc8-97e7-09606544f53a	status_update	{"status": "pending"}	{"status": "fit_call_scheduled"}	\N	35ec303c-eb7a-49e4-9244-99d18a6dda2c	2026-04-04 11:45:11.297064+05:30	2026-04-04 11:45:11.297064+05:30
1f31b86e-5ada-4b13-bed2-e9b3c3d350da	application	6c43e18a-e24a-42cd-bb54-c656823b1c32	status_update	{"status": "pending"}	{"status": "fit_call_scheduled"}	\N	28ad750d-3013-480c-9e5f-c3dc81679d48	2026-04-07 11:18:59.963339+05:30	2026-04-07 11:18:59.963339+05:30
1f31b86e-5ada-4b13-bed2-e9b3c3d350da	application	6c43e18a-e24a-42cd-bb54-c656823b1c32	status_update	{"status": "fit_call_scheduled"}	{"status": "waitlisted"}	\N	418e1c2a-cfbf-4c77-9710-90d4f05669f9	2026-04-07 11:19:10.260861+05:30	2026-04-07 11:19:10.260861+05:30
1f31b86e-5ada-4b13-bed2-e9b3c3d350da	application	6c43e18a-e24a-42cd-bb54-c656823b1c32	status_update	{"status": "waitlisted"}	{"status": "approved"}	\N	40208166-f13c-47d6-9b07-6e6c54286a5a	2026-04-07 11:19:19.56823+05:30	2026-04-07 11:19:19.56823+05:30
\.


--
-- Data for Name: businesses; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.businesses (owner_user_id, business_name, industry_category_id, district, description, website, logo_url, id, created_at, updated_at) FROM stdin;
a563e74e-3ce3-4a8a-86d3-6b6b707dcd9a	Kandy Hotel	0572680b-feba-4341-9e10-d0d8fd177be3	Kandy	\N	\N	\N	15dec714-3805-40bd-9240-9dc4b63f66f1	2026-04-02 12:42:25.241582+05:30	2026-04-02 12:42:25.241582+05:30
0f1a8890-bc4d-4d7b-9389-93f37d503b9d	TechLanka Solutions	1b93f9c6-5558-4042-9c9c-7aca5420c489	Colombo	Leading software consultancy	https://techlanka.lk	\N	3873449d-20ee-41c5-afe0-6bc38df7dea8	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
4271c0e4-5222-45fc-961a-76c6c068deaf	Peak Properties	8d02e8f1-7549-4e19-82e3-25fbf0b521f6	Kandy	Premium property development	https://peakprops.lk	\N	5d351e2f-5d13-4ce0-88cf-f66a3e8bed35	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
83aec857-8e81-4aeb-9d47-a69c4897e419	Serenity Health Clinic	bc83929a-aaca-40b3-9562-41c8ef823fda	Galle	Family healthcare services	https://serenity.lk	\N	0ca04af8-4e9d-4ecc-b0d1-74694696a1e3	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
ce0f698b-0e1f-4dd9-a2a0-91996652f2da	EduBridge Academy	37124db1-988f-4d69-810d-5ec69aad6dda	Colombo	Professional training center	https://edubridge.lk	\N	7208ebfb-7bc9-4e84-b963-309cc4e02993	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00fd49d0-339d-4284-86a6-c6d1156ce963	Lanka Capital Advisors	f835d903-aeb6-45dd-b744-15563b2e5474	Colombo	Financial advisory services	https://lankacapital.lk	\N	05393c0d-a160-4ba2-ba04-6482d0250aa7	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
230de031-45c9-4f19-a070-7140ded10152	Ceylon Grand Hotels	0572680b-feba-4341-9e10-d0d8fd177be3	Kandy	Boutique hotel chain	https://ceylongrand.lk	\N	daa9267a-c1e6-4da7-b742-67f655128268	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
55684eea-92cd-4d39-a003-b03c8f7c038d	ShopSmart Lanka	cc6aa56e-f94d-4f20-bdbb-64e4343567dd	Colombo	E-commerce marketplace	https://shopsmart.lk	\N	49bf530d-cb23-4a64-a177-9d89a44d4be1	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00ebbe6e-14c5-4d70-9156-e42221938b98	BuildRight Construction	5ae719cc-69eb-4e4d-867f-2c2a2a526689	Galle	Residential construction	https://buildright.lk	\N	0e023e68-632a-4cf2-b6e5-749d803faed3	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1cc2f625-1ba8-49de-9394-511deacf372e	LegalEase Partners	b41c4cc8-f819-45db-b762-a418a6bd4868	Colombo	Corporate law firm	https://legalease.lk	\N	00de016b-90d6-4b4a-a319-e3d2eb00ec7b	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1d26e609-7d57-48f5-86f0-5610fb3b3918	BrandPulse Digital	5f6a19d3-a9a5-4837-a086-190a20ff9425	Kandy	Digital marketing agency	https://brandpulse.lk	\N	6703ac55-230b-4530-aed0-d4816a3a1acf	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
0f1a8890-bc4d-4d7b-9389-93f37d503b9d	TechLanka Solutions	1b93f9c6-5558-4042-9c9c-7aca5420c489	Colombo	Leading software consultancy	https://techlanka.lk	\N	5e27bfb8-69aa-437f-83b6-446d2c4578fe	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
4271c0e4-5222-45fc-961a-76c6c068deaf	Peak Properties	8d02e8f1-7549-4e19-82e3-25fbf0b521f6	Kandy	Premium property development	https://peakprops.lk	\N	cbc87908-657d-4966-9efa-cd9bbec63958	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
83aec857-8e81-4aeb-9d47-a69c4897e419	Serenity Health Clinic	bc83929a-aaca-40b3-9562-41c8ef823fda	Galle	Family healthcare services	https://serenity.lk	\N	93fd83cc-d86b-4aaa-9789-32021c7a4210	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
ce0f698b-0e1f-4dd9-a2a0-91996652f2da	EduBridge Academy	37124db1-988f-4d69-810d-5ec69aad6dda	Colombo	Professional training center	https://edubridge.lk	\N	a662ad11-8b72-44af-be7e-cecfb9fa244c	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
00fd49d0-339d-4284-86a6-c6d1156ce963	Lanka Capital Advisors	f835d903-aeb6-45dd-b744-15563b2e5474	Colombo	Financial advisory services	https://lankacapital.lk	\N	6ab8d694-44b7-4c2f-af5f-fb696c3e892c	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
230de031-45c9-4f19-a070-7140ded10152	Ceylon Grand Hotels	0572680b-feba-4341-9e10-d0d8fd177be3	Kandy	Boutique hotel chain	https://ceylongrand.lk	\N	607f6314-9127-4673-a308-d1c59fb4acb3	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
55684eea-92cd-4d39-a003-b03c8f7c038d	ShopSmart Lanka	cc6aa56e-f94d-4f20-bdbb-64e4343567dd	Colombo	E-commerce marketplace	https://shopsmart.lk	\N	cbc60266-32d8-4e94-bb11-d2abca937707	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
00ebbe6e-14c5-4d70-9156-e42221938b98	BuildRight Construction	5ae719cc-69eb-4e4d-867f-2c2a2a526689	Galle	Residential construction	https://buildright.lk	\N	66c721c4-c382-459d-82e7-66fbffadb3d7	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
1cc2f625-1ba8-49de-9394-511deacf372e	LegalEase Partners	b41c4cc8-f819-45db-b762-a418a6bd4868	Colombo	Corporate law firm	https://legalease.lk	\N	7c3765b4-2904-428c-b6e2-f4dd0b92b9ab	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
1d26e609-7d57-48f5-86f0-5610fb3b3918	BrandPulse Digital	5f6a19d3-a9a5-4837-a086-190a20ff9425	Kandy	Digital marketing agency	https://brandpulse.lk	\N	b5c8647d-b3c5-4dbb-9411-e35b9b054179	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
\.


--
-- Data for Name: chapter_memberships; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.chapter_memberships (user_id, chapter_id, industry_category_id, membership_type, start_date, end_date, is_active, id, created_at, updated_at) FROM stdin;
a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	3463cd5d-e4f6-4b8f-a007-be86037aa34d	5400bbcc-e1f0-4552-ab12-ea9691f705e2	CHARTER	2026-01-01	\N	t	1ea4f6f9-9127-47a1-801f-045bd430ba77	2026-04-02 12:28:08.528293+05:30	2026-04-02 12:28:08.528293+05:30
f636cfef-f7c7-4867-91c7-fd060d0060bc	3463cd5d-e4f6-4b8f-a007-be86037aa34d	5d44d98d-1168-4c1c-884d-e7a6bdda7a4e	STANDARD	2026-04-02	2027-04-02	t	c825ef45-f1f7-48b4-bc38-28afd1da61ca	2026-04-02 12:37:02.910769+05:30	2026-04-02 12:37:02.910769+05:30
d3de2ba1-af1a-46d4-bcc7-5314de50d90b	3463cd5d-e4f6-4b8f-a007-be86037aa34d	7e18de53-ba51-432d-a955-d086b4cf2511	STANDARD	2026-04-02	2027-04-02	t	9acec7fc-6191-4bfe-b3b6-094e9d928247	2026-04-02 12:38:50.58877+05:30	2026-04-02 12:38:50.58877+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	39f4713d-47dd-49ed-9062-844da2b24b16	7232a869-af70-4cb6-89bd-7f9527787338	STANDARD	2026-04-02	\N	t	8cecc489-12f8-4285-ad98-92d456d502c7	2026-04-02 14:14:13.391771+05:30	2026-04-02 14:14:13.391771+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	6c55eb43-4bd8-4fa8-95a8-1b9f57c4a7e8	7aeba613-0d3a-404c-864f-06b779807545	STANDARD	2026-04-02	\N	t	e18e5ee1-e4f3-4f67-893f-a08e6c51e5ef	2026-04-02 14:16:10.662399+05:30	2026-04-02 14:16:10.662399+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	bfa5cfdf-7907-4bc4-a168-d595337be999	13538228-dcec-4753-8f4a-24c4a3f2c08d	STANDARD	2026-04-02	\N	t	2f37b681-37be-4702-be8b-592182050136	2026-04-02 14:17:50.164746+05:30	2026-04-02 14:17:50.164746+05:30
3cac2a2e-d280-4063-8721-eda5834edadc	e2e112ac-f2f0-4d44-bd91-6aa14ecf1b48	8573b885-2404-4f82-98c4-be80b1744ede	STANDARD	2026-04-02	\N	t	169f328b-c9ae-4a31-bbbd-6826b4c407b8	2026-04-02 14:24:14.979995+05:30	2026-04-02 14:24:14.979995+05:30
45b0f3cb-b029-4892-a64b-315483f69266	8dda840d-12a4-4c0e-b6e0-d4c5ac04c6bf	3222c722-2740-4178-9523-2032c0de800c	STANDARD	2026-04-02	\N	t	55e0e07f-3cc3-4851-be8b-346778dd939e	2026-04-02 14:24:54.523916+05:30	2026-04-02 14:24:54.523916+05:30
06e5e48d-8158-432c-986a-eeb70586154d	da1a4659-494b-40c1-b788-4db2045feb5a	48bc3243-b64c-4d9a-83e0-5e75b7cf801e	STANDARD	2026-04-02	\N	t	511b1893-04d2-47a6-8b33-c169b16695bd	2026-04-02 14:26:10.655675+05:30	2026-04-02 14:26:10.655675+05:30
9704cb54-4902-465a-849a-f48d40fe7457	d8ec1168-dc1b-4e03-99fe-020079a43abe	ca90ecbc-e566-44ee-9950-46e2689c5d17	STANDARD	2026-04-02	\N	t	61eefb65-9faa-462a-9349-5c437b83ab9f	2026-04-02 14:27:23.002144+05:30	2026-04-02 14:27:23.002144+05:30
92159ee4-fd32-408b-8130-3b5a178b473e	7c3c8bdd-40fd-40cd-89a9-eccd92476b4f	e5ed8a38-2945-497a-9f0e-944f012543ba	STANDARD	2026-04-02	\N	t	da10cfee-899d-4b10-baa4-703ddda6c331	2026-04-02 14:27:56.580107+05:30	2026-04-02 14:27:56.580107+05:30
6c0e4fdc-a0c1-4bea-9002-4a8a0e4aff01	b0db88a2-8fa1-43fe-86b4-ff317e1c314f	0637b8a1-a229-471a-845a-177c7dccee4f	STANDARD	2026-04-02	\N	t	98716fca-1584-4a9f-a720-b1872328003c	2026-04-02 14:28:16.470377+05:30	2026-04-02 14:28:16.470377+05:30
acfb3db2-398f-4a07-9d9f-50d424e242b5	e96a18ca-a56a-4b1f-82ef-5d01d715c8b9	5f0f9890-a8f8-4675-8ef9-42fcc25424fb	STANDARD	2026-04-02	\N	t	56ac2e87-7d98-478f-bf1f-fd390085fd83	2026-04-02 14:29:11.018984+05:30	2026-04-02 14:29:11.018984+05:30
8f731352-d499-40f0-bf0f-8fb4783c98ec	da4fa710-961b-42f9-9a9d-871ed74b5cc4	dba2facf-0441-4097-a162-f58db97c4638	STANDARD	2026-04-02	\N	t	540c1955-4044-4796-8ef9-434bd136e65c	2026-04-02 14:32:09.917284+05:30	2026-04-02 14:32:09.917284+05:30
3508a02a-9721-4b7c-9d8d-90f9e34a8ded	b92c881e-2e70-4de2-acc2-b1bf37249754	be391858-f07a-4196-b244-c6c53890ae98	STANDARD	2026-04-02	\N	t	49eac1e2-5df5-43ac-937c-0c28538060bc	2026-04-02 14:33:34.44711+05:30	2026-04-02 14:33:34.44711+05:30
0f1a8890-bc4d-4d7b-9389-93f37d503b9d	2cdd2005-f48c-4b59-b74a-63bf2f44b73f	5f6a19d3-a9a5-4837-a086-190a20ff9425	STANDARD	2026-01-04	\N	t	35639693-3eba-41ca-9c7b-8c962dfff32a	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
4271c0e4-5222-45fc-961a-76c6c068deaf	2cdd2005-f48c-4b59-b74a-63bf2f44b73f	37513415-22e2-4ae6-b46d-5cc99218422b	STANDARD	2026-01-04	\N	t	84ecbcff-6362-44a8-ae0d-ee1faca2c3e8	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
83aec857-8e81-4aeb-9d47-a69c4897e419	2cdd2005-f48c-4b59-b74a-63bf2f44b73f	3bf02e61-714f-4972-b1a8-ce63a7c3a1c1	STANDARD	2026-01-04	\N	t	35f57ccc-a993-4df5-84a7-38a264ad7a11	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
ce0f698b-0e1f-4dd9-a2a0-91996652f2da	2cdd2005-f48c-4b59-b74a-63bf2f44b73f	5d44d98d-1168-4c1c-884d-e7a6bdda7a4e	STANDARD	2026-01-04	\N	t	64c0ee24-4087-41c4-aab7-3d2f7f500bdb	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00fd49d0-339d-4284-86a6-c6d1156ce963	2cdd2005-f48c-4b59-b74a-63bf2f44b73f	5400bbcc-e1f0-4552-ab12-ea9691f705e2	STANDARD	2026-01-04	\N	t	4fe3b1c8-f5ab-44ed-88a7-315fe6649d01	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
230de031-45c9-4f19-a070-7140ded10152	b374baeb-8725-474d-b314-00e430730218	7e18de53-ba51-432d-a955-d086b4cf2511	STANDARD	2026-01-04	\N	t	abf3434f-b3b8-4471-a2f8-3d5a370e3127	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
55684eea-92cd-4d39-a003-b03c8f7c038d	b374baeb-8725-474d-b314-00e430730218	0572680b-feba-4341-9e10-d0d8fd177be3	STANDARD	2026-01-04	\N	t	441f0360-0ee1-4921-bccf-fb73929acf80	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00ebbe6e-14c5-4d70-9156-e42221938b98	b374baeb-8725-474d-b314-00e430730218	226503f1-1ab8-41c9-83e4-5f0a5917afb2	STANDARD	2026-01-04	\N	t	47564b62-0bd1-49fc-9a1f-a917f489524e	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1cc2f625-1ba8-49de-9394-511deacf372e	2f05425b-4ec5-40a5-aeaf-bf2412a96251	7232a869-af70-4cb6-89bd-7f9527787338	STANDARD	2026-01-04	\N	t	2b07bc45-bc35-412d-895b-1c0789d0674d	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1d26e609-7d57-48f5-86f0-5610fb3b3918	2f05425b-4ec5-40a5-aeaf-bf2412a96251	7aeba613-0d3a-404c-864f-06b779807545	STANDARD	2026-01-04	\N	t	e5368822-ab97-41f5-a5b9-61b20aa6dbf7	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1f31b86e-5ada-4b13-bed2-e9b3c3d350da	8dda840d-12a4-4c0e-b6e0-d4c5ac04c6bf	1b93f9c6-5558-4042-9c9c-7aca5420c489	STANDARD	2026-04-07	2027-04-07	t	27cf1cd5-8b38-4a01-a6e8-de1558f7283b	2026-04-07 11:19:19.56823+05:30	2026-04-07 11:19:19.56823+05:30
\.


--
-- Data for Name: chapters; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.chapters (name, description, meeting_schedule, is_active, id, created_at, updated_at) FROM stdin;
Colombo Main	\N	\N	t	3463cd5d-e4f6-4b8f-a007-be86037aa34d	2026-04-02 12:26:25.328491+05:30	2026-04-02 12:26:25.328491+05:30
Kandy Business Hub	\N	\N	t	580c5d0a-714f-49a1-a4e7-afddcddc6993	2026-04-02 12:42:25.241582+05:30	2026-04-02 12:42:25.241582+05:30
Colombo Central	\N	\N	t	6c4fc064-b4df-4d98-a656-57b6b10fb5b6	2026-04-02 13:41:55.090806+05:30	2026-04-02 13:41:55.090806+05:30
Global Business Hub	\N	\N	t	4fa25650-5e3a-41b1-bc37-d28b2645b636	2026-04-02 14:11:02.831493+05:30	2026-04-02 14:11:02.831493+05:30
Analytics Chapter 0ecf52	\N	\N	t	39f4713d-47dd-49ed-9062-844da2b24b16	2026-04-02 14:14:13.391771+05:30	2026-04-02 14:14:13.391771+05:30
Analytics Chapter f1250e	\N	\N	t	6c55eb43-4bd8-4fa8-95a8-1b9f57c4a7e8	2026-04-02 14:16:10.662399+05:30	2026-04-02 14:16:10.662399+05:30
Analytics Chapter d3f5ba	\N	\N	t	bfa5cfdf-7907-4bc4-a168-d595337be999	2026-04-02 14:17:50.164746+05:30	2026-04-02 14:17:50.164746+05:30
Pay Chapter 16660	\N	\N	t	e2e112ac-f2f0-4d44-bd91-6aa14ecf1b48	2026-04-02 14:24:14.979995+05:30	2026-04-02 14:24:14.979995+05:30
Pay Chapter 65772	\N	\N	t	8dda840d-12a4-4c0e-b6e0-d4c5ac04c6bf	2026-04-02 14:24:54.523916+05:30	2026-04-02 14:24:54.523916+05:30
Pay Chapter 51894	\N	\N	t	da1a4659-494b-40c1-b788-4db2045feb5a	2026-04-02 14:26:10.655675+05:30	2026-04-02 14:26:10.655675+05:30
Pay Chapter 91070	\N	\N	t	d8ec1168-dc1b-4e03-99fe-020079a43abe	2026-04-02 14:27:23.002144+05:30	2026-04-02 14:27:23.002144+05:30
Pay Chapter 88726	\N	\N	t	7c3c8bdd-40fd-40cd-89a9-eccd92476b4f	2026-04-02 14:27:56.580107+05:30	2026-04-02 14:27:56.580107+05:30
Pay Chapter 14258	\N	\N	t	b0db88a2-8fa1-43fe-86b4-ff317e1c314f	2026-04-02 14:28:16.470377+05:30	2026-04-02 14:28:16.470377+05:30
Pay Chapter 9100	\N	\N	t	e96a18ca-a56a-4b1f-82ef-5d01d715c8b9	2026-04-02 14:29:11.018984+05:30	2026-04-02 14:29:11.018984+05:30
Pay Chapter 1490	\N	\N	t	da4fa710-961b-42f9-9a9d-871ed74b5cc4	2026-04-02 14:32:09.917284+05:30	2026-04-02 14:32:09.917284+05:30
Pay Chapter 2315	\N	\N	t	b92c881e-2e70-4de2-acc2-b1bf37249754	2026-04-02 14:33:34.44711+05:30	2026-04-02 14:33:34.44711+05:30
Colombo Chapter	Main chapter covering the Colombo metropolitan area	Every Wednesday 7:00 PM	t	2cdd2005-f48c-4b59-b74a-63bf2f44b73f	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Kandy Chapter	Central province chapter based in Kandy	Every Thursday 6:30 PM	t	b374baeb-8725-474d-b314-00e430730218	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Galle Chapter	Southern province chapter covering Galle and surroundings	Every Friday 7:00 PM	t	2f05425b-4ec5-40a5-aeaf-bf2412a96251	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
\.


--
-- Data for Name: coupon_codes; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.coupon_codes (offer_id, user_id, code, status, used_at, expires_at, id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: event_attendance; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.event_attendance (event_id, user_id, marked_at, marked_by, id, created_at, updated_at) FROM stdin;
71210656-4a0c-48dc-a3df-fd41eef94b1d	a7bc50cc-b0fd-4c9e-91bd-6004e76235bf	2026-04-02 13:51:01.731275+05:30	95805690-eb07-42bc-bf2a-645261d928af	9fca631b-465e-434f-b217-91f966b86317	2026-04-02 13:51:01.726532+05:30	2026-04-02 13:51:01.726532+05:30
\.


--
-- Data for Name: event_rsvps; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.event_rsvps (event_id, user_id, status, id, created_at, updated_at) FROM stdin;
71210656-4a0c-48dc-a3df-fd41eef94b1d	a7bc50cc-b0fd-4c9e-91bd-6004e76235bf	NOT_GOING	9d2cc51a-6b13-44e9-99c4-b42ae543a098	2026-04-02 13:50:57.598339+05:30	2026-04-02 13:50:59.673234+05:30
53f872b4-b224-4cc3-a596-f4344ee809c3	3508a02a-9721-4b7c-9d8d-90f9e34a8ded	GOING	d36026c2-f311-4775-95ff-a40cb42196ee	2026-04-02 14:33:58.257318+05:30	2026-04-02 14:33:58.257318+05:30
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.events (chapter_id, title, description, event_type, location, meeting_link, start_at, end_at, fee, max_attendees, is_published, is_active, id, created_at, updated_at) FROM stdin;
6c4fc064-b4df-4d98-a656-57b6b10fb5b6	Monthly Network Meetup	\N	FLAGSHIP	Shangri-La Colombo	\N	2026-04-09 13:50:49.392276+05:30	2026-04-09 15:50:49.392299+05:30	0.00	\N	t	t	71210656-4a0c-48dc-a3df-fd41eef94b1d	2026-04-02 13:50:53.48849+05:30	2026-04-02 13:50:53.48849+05:30
e2e112ac-f2f0-4d44-bd91-6aa14ecf1b48	Payments Test Event 16660	\N	FLAGSHIP	\N	\N	2026-04-09 14:24:14.857541+05:30	2026-04-09 16:24:14.857541+05:30	0.00	\N	t	t	c0f6db10-312a-4bc6-8832-24d88ee51bd4	2026-04-02 14:24:14.979995+05:30	2026-04-02 14:24:14.979995+05:30
8dda840d-12a4-4c0e-b6e0-d4c5ac04c6bf	Payments Test Event 65772	\N	FLAGSHIP	\N	\N	2026-04-09 14:24:54.439759+05:30	2026-04-09 16:24:54.439759+05:30	0.00	\N	t	t	4ec13e93-cf29-4ed7-81ef-f891cf93ef6c	2026-04-02 14:24:54.523916+05:30	2026-04-02 14:24:54.523916+05:30
da1a4659-494b-40c1-b788-4db2045feb5a	Payments Test Event 51894	\N	FLAGSHIP	\N	\N	2026-04-09 14:26:10.521441+05:30	2026-04-09 16:26:10.521441+05:30	0.00	\N	t	t	949148e1-b8b2-4711-a6d7-7583cb593318	2026-04-02 14:26:10.655675+05:30	2026-04-02 14:26:10.655675+05:30
d8ec1168-dc1b-4e03-99fe-020079a43abe	Payments Test Event 91070	\N	FLAGSHIP	\N	\N	2026-04-09 14:27:22.922366+05:30	2026-04-09 16:27:22.922366+05:30	0.00	\N	t	t	c0909171-1459-4eca-a60f-bceba23b9a9e	2026-04-02 14:27:23.002144+05:30	2026-04-02 14:27:23.002144+05:30
7c3c8bdd-40fd-40cd-89a9-eccd92476b4f	Payments Test Event 88726	\N	FLAGSHIP	\N	\N	2026-04-09 14:27:56.500368+05:30	2026-04-09 16:27:56.500368+05:30	0.00	\N	t	t	866f1ff4-6981-48c3-97ec-02e2f2423abb	2026-04-02 14:27:56.580107+05:30	2026-04-02 14:27:56.580107+05:30
b0db88a2-8fa1-43fe-86b4-ff317e1c314f	Payments Test Event 14258	\N	FLAGSHIP	\N	\N	2026-04-09 14:28:16.389061+05:30	2026-04-09 16:28:16.389061+05:30	0.00	\N	t	t	cbf8cd6a-49ab-4c72-a3b0-99f734b14ec9	2026-04-02 14:28:16.470377+05:30	2026-04-02 14:28:16.470377+05:30
e96a18ca-a56a-4b1f-82ef-5d01d715c8b9	Payments Test Event 9100	\N	FLAGSHIP	\N	\N	2026-04-09 14:29:10.939305+05:30	2026-04-09 16:29:10.939305+05:30	0.00	\N	t	t	4a395a51-0b25-4075-81e4-da1e9d213bbc	2026-04-02 14:29:11.018984+05:30	2026-04-02 14:29:11.018984+05:30
da4fa710-961b-42f9-9a9d-871ed74b5cc4	Payments Test Event 1490	\N	FLAGSHIP	\N	\N	2026-04-09 14:32:09.812972+05:30	2026-04-09 16:32:09.812972+05:30	0.00	\N	t	t	ab28275b-d5ca-4e2a-a3d6-a6d8a8823bb4	2026-04-02 14:32:09.917284+05:30	2026-04-02 14:32:09.917284+05:30
b92c881e-2e70-4de2-acc2-b1bf37249754	Payments Test Event 2315	\N	FLAGSHIP	\N	\N	2026-04-09 14:33:34.260326+05:30	2026-04-09 16:33:34.260326+05:30	0.00	\N	t	t	53f872b4-b224-4cc3-a596-f4344ee809c3	2026-04-02 14:33:34.44711+05:30	2026-04-02 14:33:34.44711+05:30
2cdd2005-f48c-4b59-b74a-63bf2f44b73f	Monthly Networking Mixer	Connect with fellow members over refreshments	FLAGSHIP	Cinnamon Grand, Colombo	\N	2026-04-11 07:38:16.343367+05:30	2026-04-11 10:38:16.343367+05:30	500.00	50	t	t	183ba6c4-6696-4b6c-8f75-618eda934565	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
2cdd2005-f48c-4b59-b74a-63bf2f44b73f	Tech Innovation Summit	Explore latest tech trends in Sri Lanka	FLAGSHIP	BMICH, Colombo	\N	2026-04-18 07:38:16.343367+05:30	2026-04-18 11:38:16.343367+05:30	1000.00	100	t	t	b938543a-3350-4a95-b4e3-776927a6c155	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
b374baeb-8725-474d-b314-00e430730218	Virtual Business Workshop	Learn best practices for scaling your business	VIRTUAL	\N	https://zoom.us/j/123	2026-04-14 07:38:16.343367+05:30	2026-04-14 09:38:16.343367+05:30	0.00	\N	t	t	d2d5ea77-a3e6-410c-a4f5-10c927c3b73e	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
b374baeb-8725-474d-b314-00e430730218	Kandy Business Breakfast	Early morning networking with central province leaders	MICRO_MEETUP	Queens Hotel, Kandy	\N	2026-04-09 07:38:16.343367+05:30	2026-04-09 09:38:16.343367+05:30	750.00	30	t	t	576fb34e-e348-4442-b40b-421e23552dc5	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
2f05425b-4ec5-40a5-aeaf-bf2412a96251	Southern Entrepreneurs Meet	Quarterly meetup for southern province members	FLAGSHIP	Jetwing Lighthouse, Galle	\N	2026-04-25 07:38:16.343367+05:30	2026-04-25 10:38:16.343367+05:30	1500.00	40	t	t	c86bb7ee-3fb4-4ad3-8aaf-de0813e4b1b5	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
2f05425b-4ec5-40a5-aeaf-bf2412a96251	Online Marketing Masterclass	Digital marketing strategies for local businesses	VIRTUAL	\N	https://zoom.us/j/456	2026-04-07 07:38:16.343367+05:30	2026-04-07 09:38:16.343367+05:30	0.00	\N	t	t	3c99925c-dd7c-439f-bbe2-a8714130b294	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
2cdd2005-f48c-4b59-b74a-63bf2f44b73f	Monthly Networking Mixer	Connect with fellow members over refreshments	FLAGSHIP	Cinnamon Grand, Colombo	\N	2026-04-11 07:38:28.932648+05:30	2026-04-11 10:38:28.932648+05:30	500.00	50	t	t	62e0797b-003e-4e0c-ae55-d346e821da46	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
2cdd2005-f48c-4b59-b74a-63bf2f44b73f	Tech Innovation Summit	Explore latest tech trends in Sri Lanka	FLAGSHIP	BMICH, Colombo	\N	2026-04-18 07:38:28.932648+05:30	2026-04-18 11:38:28.932648+05:30	1000.00	100	t	t	bba87d01-8960-4a1b-9cb4-7fee6909a441	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
b374baeb-8725-474d-b314-00e430730218	Virtual Business Workshop	Learn best practices for scaling your business	VIRTUAL	\N	https://zoom.us/j/123	2026-04-14 07:38:28.932648+05:30	2026-04-14 09:38:28.932648+05:30	0.00	\N	t	t	67d56d7c-f019-4a98-af1c-ccc19317e677	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
b374baeb-8725-474d-b314-00e430730218	Kandy Business Breakfast	Early morning networking with central province leaders	MICRO_MEETUP	Queens Hotel, Kandy	\N	2026-04-09 07:38:28.932648+05:30	2026-04-09 09:38:28.932648+05:30	750.00	30	t	t	80bdcf77-dae0-4ec1-947f-b9234533d1f3	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
2f05425b-4ec5-40a5-aeaf-bf2412a96251	Southern Entrepreneurs Meet	Quarterly meetup for southern province members	FLAGSHIP	Jetwing Lighthouse, Galle	\N	2026-04-25 07:38:28.932648+05:30	2026-04-25 10:38:28.932648+05:30	1500.00	40	t	t	497eb2a2-a8ac-4ebe-9bfa-a236a919b4e8	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
2f05425b-4ec5-40a5-aeaf-bf2412a96251	Online Marketing Masterclass	Digital marketing strategies for local businesses	VIRTUAL	\N	https://zoom.us/j/456	2026-04-07 07:38:28.932648+05:30	2026-04-07 09:38:28.932648+05:30	0.00	\N	t	t	9c28bac2-7f6c-4be3-a908-4c15fbe48c66	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
\.


--
-- Data for Name: industry_categories; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.industry_categories (name, slug, description, is_active, id, created_at, updated_at) FROM stdin;
Marketing & Advertising	marketing-advertising	Digital marketing, branding, PR	t	5f6a19d3-a9a5-4837-a086-190a20ff9425	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Automotive	automotive	Vehicles, spare parts, services	t	37513415-22e2-4ae6-b46d-5cc99218422b	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Manufacturing	manufacturing	Production, textiles, machinery	t	3bf02e61-714f-4972-b1a8-ce63a7c3a1c1	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Marketing	marketing	\N	t	5d44d98d-1168-4c1c-884d-e7a6bdda7a4e	2026-04-02 12:36:45.372168+05:30	2026-04-02 12:36:45.372168+05:30
Tech	tech	\N	t	5400bbcc-e1f0-4552-ab12-ea9691f705e2	2026-04-02 12:26:25.328491+05:30	2026-04-02 12:26:25.328491+05:30
Marketing 8000	marketing-8000	\N	t	7e18de53-ba51-432d-a955-d086b4cf2511	2026-04-02 12:38:30.718186+05:30	2026-04-02 12:38:30.718186+05:30
Hospitality	hospitality	\N	t	0572680b-feba-4341-9e10-d0d8fd177be3	2026-04-02 12:42:25.241582+05:30	2026-04-02 12:42:25.241582+05:30
Tech Consulting	tech-consulting-2	\N	t	226503f1-1ab8-41c9-83e4-5f0a5917afb2	2026-04-02 14:11:02.831493+05:30	2026-04-02 14:11:02.831493+05:30
Analytic Cat 51d9ff	an-cat-6cc9b8	\N	t	7232a869-af70-4cb6-89bd-7f9527787338	2026-04-02 14:14:13.391771+05:30	2026-04-02 14:14:13.391771+05:30
Analytic Cat d5f7c0	an-cat-1c1871	\N	t	7aeba613-0d3a-404c-864f-06b779807545	2026-04-02 14:16:10.662399+05:30	2026-04-02 14:16:10.662399+05:30
Analytic Cat 3c9ccd	an-cat-4b40fb	\N	t	13538228-dcec-4753-8f4a-24c4a3f2c08d	2026-04-02 14:17:50.164746+05:30	2026-04-02 14:17:50.164746+05:30
Pay Cat 16660	pay-cat-16660	\N	t	8573b885-2404-4f82-98c4-be80b1744ede	2026-04-02 14:24:14.979995+05:30	2026-04-02 14:24:14.979995+05:30
Pay Cat 65772	pay-cat-65772	\N	t	3222c722-2740-4178-9523-2032c0de800c	2026-04-02 14:24:54.523916+05:30	2026-04-02 14:24:54.523916+05:30
Pay Cat 51894	pay-cat-51894	\N	t	48bc3243-b64c-4d9a-83e0-5e75b7cf801e	2026-04-02 14:26:10.655675+05:30	2026-04-02 14:26:10.655675+05:30
Pay Cat 91070	pay-cat-91070	\N	t	ca90ecbc-e566-44ee-9950-46e2689c5d17	2026-04-02 14:27:23.002144+05:30	2026-04-02 14:27:23.002144+05:30
Pay Cat 88726	pay-cat-88726	\N	t	e5ed8a38-2945-497a-9f0e-944f012543ba	2026-04-02 14:27:56.580107+05:30	2026-04-02 14:27:56.580107+05:30
Pay Cat 14258	pay-cat-14258	\N	t	0637b8a1-a229-471a-845a-177c7dccee4f	2026-04-02 14:28:16.470377+05:30	2026-04-02 14:28:16.470377+05:30
Pay Cat 9100	pay-cat-9100	\N	t	5f0f9890-a8f8-4675-8ef9-42fcc25424fb	2026-04-02 14:29:11.018984+05:30	2026-04-02 14:29:11.018984+05:30
Pay Cat 1490	pay-cat-1490	\N	t	dba2facf-0441-4097-a162-f58db97c4638	2026-04-02 14:32:09.917284+05:30	2026-04-02 14:32:09.917284+05:30
Pay Cat 2315	pay-cat-2315	\N	t	be391858-f07a-4196-b244-c6c53890ae98	2026-04-02 14:33:34.44711+05:30	2026-04-02 14:33:34.44711+05:30
Information Technology	information-technology	Software, IT services, cyber security	t	1b93f9c6-5558-4042-9c9c-7aca5420c489	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Real Estate	real-estate	Property development and management	t	8d02e8f1-7549-4e19-82e3-25fbf0b521f6	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Healthcare	healthcare	Medical services, pharmaceuticals	t	bc83929a-aaca-40b3-9562-41c8ef823fda	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Education	education	Schools, tutoring, training	t	37124db1-988f-4d69-810d-5ec69aad6dda	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Finance & Banking	finance-banking	Banking, insurance, investments	t	f835d903-aeb6-45dd-b744-15563b2e5474	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Retail & E-Commerce	retail-ecommerce	Online and offline retail	t	cc6aa56e-f94d-4f20-bdbb-64e4343567dd	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Construction	construction	Building, engineering, architecture	t	5ae719cc-69eb-4e4d-867f-2c2a2a526689	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
Legal Services	legal-services	Law firms, notaries, consulting	t	b41c4cc8-f819-45db-b762-a418a6bd4868	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.notifications (user_id, title, body, notification_type, data, is_read, sent_at, read_at, id, created_at, updated_at) FROM stdin;
049253b2-932e-4866-b032-38183af662af	Test Notification 🎉	If you read this, the FCM module is functioning correctly for your device.	system_test	{"route": "/profile"}	t	2026-04-02 16:38:23.765704+05:30	2026-04-02 16:38:30.960546+05:30	ec0107fb-2865-483a-893d-ad2272024e40	2026-04-02 16:38:23.768813+05:30	2026-04-02 16:38:30.961367+05:30
049253b2-932e-4866-b032-38183af662af	Test Notification 🎉	If you read this, the FCM module is functioning correctly for your device.	system_test	{"route": "/profile"}	t	2026-04-02 16:38:35.030766+05:30	2026-04-02 16:38:42.203797+05:30	3a0ffc08-38bb-420d-ba4b-9a433f1d2677	2026-04-02 16:38:35.03248+05:30	2026-04-02 16:38:42.204949+05:30
049253b2-932e-4866-b032-38183af662af	Test Notification 🎉	If you read this, the FCM module is functioning correctly for your device.	system_test	{"route": "/profile"}	t	2026-04-02 16:38:37.133083+05:30	2026-04-02 16:38:42.203797+05:30	9004b209-129a-4483-9fe9-a88d64d18f9c	2026-04-02 16:38:37.184325+05:30	2026-04-02 16:38:42.204949+05:30
\.


--
-- Data for Name: offer_redemptions; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.offer_redemptions (offer_id, user_id, redeemed_at, id, created_at, updated_at, redemption_token_id) FROM stdin;
ac76180c-f738-4265-b5d4-451d56186df2	084c432a-251a-4542-ad8d-16d9940e47ce	2026-04-02 13:58:11.257275+05:30	2527fd66-c5ae-480f-9ec7-9613c026861c	2026-04-02 13:58:11.254901+05:30	2026-04-02 13:58:11.254901+05:30	\N
ac76180c-f738-4265-b5d4-451d56186df2	09479f7e-cde2-4579-a192-e1f7ed34e03f	2026-04-04 13:00:35.737164+05:30	400984d0-2b16-4e80-ab4f-30c902c99fc7	2026-04-04 13:00:35.710359+05:30	2026-04-04 13:00:35.710359+05:30	\N
ac76180c-f738-4265-b5d4-451d56186df2	00fd49d0-339d-4284-86a6-c6d1156ce963	2026-04-06 16:30:50.480459+05:30	7e1b5a59-8edc-4475-a85a-d2d4f72820ef	2026-04-06 16:30:50.448585+05:30	2026-04-06 16:30:50.448585+05:30	\N
09003cd2-2355-4495-9e1f-387a74babd9a	00fd49d0-339d-4284-86a6-c6d1156ce963	2026-04-06 16:30:57.378146+05:30	18f1f2af-6fc6-4ce7-919b-a8c74766546c	2026-04-06 16:30:57.374959+05:30	2026-04-06 16:30:57.374959+05:30	\N
ac76180c-f738-4265-b5d4-451d56186df2	8dd6b091-4eb1-42b8-9865-b20d538908f1	2026-04-06 17:03:49.202982+05:30	a8d96d96-6a74-4ca3-aefd-457a56473d06	2026-04-06 17:03:49.168932+05:30	2026-04-06 17:03:49.168932+05:30	924f5821-d812-4ca7-b36e-85c618911431
\.


--
-- Data for Name: offers; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.offers (partner_id, title, description, offer_type, discount_percentage, start_date, end_date, is_active, redemption_instructions, id, created_at, updated_at) FROM stdin;
e43da0cb-ac8c-431a-8e5f-bfdcff6da8a9	20% Off Buffet	\N	DISCOUNT	20	2026-04-02	2026-05-02	t	\N	ac76180c-f738-4265-b5d4-451d56186df2	2026-04-02 13:58:07.155894+05:30	2026-04-02 13:58:07.155894+05:30
67307268-e2d6-4287-b540-fc4af61d2e2f	15% Off Electronics	Get 15% off on all Softlogic electronics	DISCOUNT	15	2026-04-04	2026-07-03	t	Show PBN privilege card at checkout	09003cd2-2355-4495-9e1f-387a74babd9a	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
67307268-e2d6-4287-b540-fc4af61d2e2f	Free Delivery on Furniture	Free delivery for all furniture purchases above 50K	FREE_ITEM	\N	2026-04-04	2026-06-03	t	Mention PBN membership at order	bf0443e5-c4a6-4458-ad96-8479eef92f03	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1f0e26f0-ddc7-47c4-ba71-de1a067a3646	20% Off Spa Treatments	Exclusive spa treatment discount for PBN members	DISCOUNT	20	2026-04-04	2026-08-02	t	Book via PBN app and show card	e30ffb19-0ed9-4aff-a0c7-57b8c84f6f36	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
c42b2eef-67b5-4857-baf9-680ac2cdd66b	Free Data Pack	1GB free data on any Dialog postpaid plan	FREE_ITEM	\N	2026-04-04	2026-05-04	t	Dial *123# and enter PBN code	2ff88ec4-3cd0-47da-a882-766bc22d9c26	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
9f1ce1cf-e568-4656-a140-ac27bca2b245	15% Off Electronics	Get 15% off on all Softlogic electronics	DISCOUNT	15	2026-04-04	2026-07-03	t	Show PBN privilege card at checkout	65ded499-e08c-45a2-8954-21cfc7871d4d	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
9f1ce1cf-e568-4656-a140-ac27bca2b245	Free Delivery on Furniture	Free delivery for all furniture purchases above 50K	FREE_ITEM	\N	2026-04-04	2026-06-03	t	Mention PBN membership at order	edab898e-8537-460b-928d-e7c37146979c	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
74d24566-f749-471f-994e-5630dcfe25b6	20% Off Spa Treatments	Exclusive spa treatment discount for PBN members	DISCOUNT	20	2026-04-04	2026-08-02	t	Book via PBN app and show card	e16ce541-9bf7-4b06-9659-93b539c67f2b	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
24eec2d9-f6b9-47a5-af6b-bd901a5c701e	Free Data Pack	1GB free data on any Dialog postpaid plan	FREE_ITEM	\N	2026-04-04	2026-05-04	t	Dial *123# and enter PBN code	bb7a4bea-ae39-4047-8149-3f68b2c237f2	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
\.


--
-- Data for Name: partners; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.partners (name, logo_url, description, website, is_active, id, created_at, updated_at, admin_id) FROM stdin;
Hilton Colombo	\N	5-star hotel	\N	t	e43da0cb-ac8c-431a-8e5f-bfdcff6da8a9	2026-04-02 13:58:05.111772+05:30	2026-04-06 17:48:15.327525+05:30	cfd80713-e8e8-4a00-abf8-29ff9135096a
Softlogic Holdings	\N	Sri Lanka's leading retail and finance conglomerate	https://softlogic.lk	t	67307268-e2d6-4287-b540-fc4af61d2e2f	2026-04-04 07:38:16.343367+05:30	2026-04-06 17:48:15.339238+05:30	10ffb73c-4cc4-4706-9f47-21819fb0a24c
Spa Ceylon	\N	Premium Ayurveda and wellness brand	https://spaceylon.com	t	1f0e26f0-ddc7-47c4-ba71-de1a067a3646	2026-04-04 07:38:16.343367+05:30	2026-04-06 17:48:15.341784+05:30	5fa4a3ea-e214-4c7a-9ce0-8f9fb71b07ec
Dialog Axiata	\N	Telecommunications and digital services	https://dialog.lk	t	c42b2eef-67b5-4857-baf9-680ac2cdd66b	2026-04-04 07:38:16.343367+05:30	2026-04-06 17:48:15.344396+05:30	1b09fbbb-5165-4478-bdf8-88243df43273
Softlogic Holdings	\N	Sri Lanka's leading retail and finance conglomerate	https://softlogic.lk	t	9f1ce1cf-e568-4656-a140-ac27bca2b245	2026-04-04 07:38:28.932648+05:30	2026-04-06 17:48:15.34724+05:30	8ec8681b-6029-4a3b-a1cb-bc5bbd164c19
Spa Ceylon	\N	Premium Ayurveda and wellness brand	https://spaceylon.com	t	74d24566-f749-471f-994e-5630dcfe25b6	2026-04-04 07:38:28.932648+05:30	2026-04-06 17:48:15.349664+05:30	a4ad94ae-cede-4d98-a890-40acb26bf51a
Dialog Axiata	\N	Telecommunications and digital services	https://dialog.lk	t	24eec2d9-f6b9-47a5-af6b-bd901a5c701e	2026-04-04 07:38:28.932648+05:30	2026-04-06 17:48:15.351994+05:30	777702ba-5b43-4388-89f7-797cb3f3b043
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.payments (user_id, amount, currency, payment_type, reference_id, gateway_reference, status, gateway_response, id, created_at, updated_at) FROM stdin;
acfb3db2-398f-4a07-9d9f-50d424e242b5	6000.00	LKR	MEETING_FEE	4a395a51-0b25-4075-81e4-da1e9d213bbc	PBN-8208CB806DAC	PENDING	\N	fa119b4b-99c1-4f79-bcb8-378d90312689	2026-04-02 14:29:25.761058+05:30	2026-04-02 14:29:25.790411+05:30
3508a02a-9721-4b7c-9d8d-90f9e34a8ded	25000.00	LKR	MEMBERSHIP	\N	PBN-527AF0D933BC	PENDING	\N	9b74fad9-8b81-4f62-b1c1-34871cd366c9	2026-04-02 14:33:52.045039+05:30	2026-04-02 14:33:52.049636+05:30
3508a02a-9721-4b7c-9d8d-90f9e34a8ded	6000.00	LKR	MEETING_FEE	53f872b4-b224-4cc3-a596-f4344ee809c3	PBN-2501E900E31B	COMPLETED	{"md5sig": "SIMULATED", "order_id": "SIMULATED", "simulated": true, "payment_id": "b2f276ed-0c5a-4979-aa7b-e4fc3b43f83f", "status_code": "2"}	b2f276ed-0c5a-4979-aa7b-e4fc3b43f83f	2026-04-02 14:33:49.95721+05:30	2026-04-02 14:33:58.267027+05:30
0f1a8890-bc4d-4d7b-9389-93f37d503b9d	25000.00	LKR	MEMBERSHIP	PBN-MEM-0001	\N	COMPLETED	\N	ff41572e-4bcb-484f-b207-d98792e7aa00	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
4271c0e4-5222-45fc-961a-76c6c068deaf	26000.00	LKR	MEMBERSHIP	PBN-MEM-0002	\N	COMPLETED	\N	570b781c-e880-46cb-b485-cffc4b0b7f7f	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
83aec857-8e81-4aeb-9d47-a69c4897e419	27000.00	LKR	MEMBERSHIP	PBN-MEM-0003	\N	COMPLETED	\N	dfbf1872-cdd3-4e16-840b-a6651f1e6a2a	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
ce0f698b-0e1f-4dd9-a2a0-91996652f2da	28000.00	LKR	MEMBERSHIP	PBN-MEM-0004	\N	COMPLETED	\N	f8d719f6-fe72-4db4-b8b7-687e9857f118	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00fd49d0-339d-4284-86a6-c6d1156ce963	29000.00	LKR	MEMBERSHIP	PBN-MEM-0005	\N	COMPLETED	\N	7c0a31f3-005a-4c75-b37f-978ae7cec920	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
230de031-45c9-4f19-a070-7140ded10152	30000.00	LKR	MEMBERSHIP	PBN-MEM-0006	\N	COMPLETED	\N	f61a76dc-48ff-4209-8da7-3aa9292ec0ae	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
55684eea-92cd-4d39-a003-b03c8f7c038d	31000.00	LKR	MEMBERSHIP	PBN-MEM-0007	\N	COMPLETED	\N	14439502-4c6b-47f8-8800-547b52182d5c	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00ebbe6e-14c5-4d70-9156-e42221938b98	32000.00	LKR	MEMBERSHIP	PBN-MEM-0008	\N	COMPLETED	\N	5028ae93-1e43-480f-b04f-11a7dc78acf7	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1cc2f625-1ba8-49de-9394-511deacf372e	33000.00	LKR	MEMBERSHIP	PBN-MEM-0009	\N	COMPLETED	\N	62310462-fa6a-45d3-bb03-696d55f54ead	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1d26e609-7d57-48f5-86f0-5610fb3b3918	34000.00	LKR	MEMBERSHIP	PBN-MEM-0010	\N	COMPLETED	\N	f2664857-4bf9-4240-8ad4-6b9ed0c8644e	2026-01-09 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
0f1a8890-bc4d-4d7b-9389-93f37d503b9d	25000.00	LKR	MEMBERSHIP	PBN-MEM-0001	\N	COMPLETED	\N	e19284a7-8c20-4d72-aab3-b4ce13fa5293	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
4271c0e4-5222-45fc-961a-76c6c068deaf	26000.00	LKR	MEMBERSHIP	PBN-MEM-0002	\N	COMPLETED	\N	593a790b-90d8-4775-841e-3c610c4be8c4	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
83aec857-8e81-4aeb-9d47-a69c4897e419	27000.00	LKR	MEMBERSHIP	PBN-MEM-0003	\N	COMPLETED	\N	6605d276-03cf-41ba-ac2d-8cf10a7dc684	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
ce0f698b-0e1f-4dd9-a2a0-91996652f2da	28000.00	LKR	MEMBERSHIP	PBN-MEM-0004	\N	COMPLETED	\N	784b7bf5-a92f-40ee-91b1-74c13c429d96	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
00fd49d0-339d-4284-86a6-c6d1156ce963	29000.00	LKR	MEMBERSHIP	PBN-MEM-0005	\N	COMPLETED	\N	a9ef7a5b-f5b6-47b4-af42-01676665972c	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
230de031-45c9-4f19-a070-7140ded10152	30000.00	LKR	MEMBERSHIP	PBN-MEM-0006	\N	COMPLETED	\N	2f68693b-8f38-489e-9da5-0f03bdf31fc9	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
55684eea-92cd-4d39-a003-b03c8f7c038d	31000.00	LKR	MEMBERSHIP	PBN-MEM-0007	\N	COMPLETED	\N	5e861c8a-bd75-41d6-9088-9e3722648975	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
00ebbe6e-14c5-4d70-9156-e42221938b98	32000.00	LKR	MEMBERSHIP	PBN-MEM-0008	\N	COMPLETED	\N	361e959e-db48-455d-8a5e-6eda8a7c4074	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
1cc2f625-1ba8-49de-9394-511deacf372e	33000.00	LKR	MEMBERSHIP	PBN-MEM-0009	\N	COMPLETED	\N	92bf6b54-a2b5-4795-92ea-920a945bfa25	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
1d26e609-7d57-48f5-86f0-5610fb3b3918	34000.00	LKR	MEMBERSHIP	PBN-MEM-0010	\N	COMPLETED	\N	15a81799-771d-458e-beb3-37fb4aa04ae7	2026-01-09 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
\.


--
-- Data for Name: privilege_cards; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.privilege_cards (user_id, card_number, qr_code_data, is_active, issued_at, expires_at, id, created_at, updated_at) FROM stdin;
f636cfef-f7c7-4867-91c7-fd060d0060bc	PBN8116400	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjYXJkX251bWJlciI6IlBCTjgxMTY0MDAiLCJ1c2VyX2lkIjoiZjYzNmNmZWYtZjdjNy00ODY3LTkxYzctZmQwNjBkMDA2MGJjIiwiZXhwIjoxODA2NjQ5NjIyfQ.FXzdS-4eyuidT2efAfnH41PO6RdQPMVGz4hGtel3NFs	t	2026-04-02 12:37:02.933936+05:30	2027-04-02 12:37:02.933773+05:30	4f006ee0-7e2b-4bdf-8b60-2fc25fe0a80d	2026-04-02 12:37:02.910769+05:30	2026-04-02 12:37:02.910769+05:30
d3de2ba1-af1a-46d4-bcc7-5314de50d90b	PBN5692443	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjYXJkX251bWJlciI6IlBCTjU2OTI0NDMiLCJ1c2VyX2lkIjoiZDNkZTJiYTEtYWYxYS00NmQ0LWJjYzctNTMxNGRlNTBkOTBiIiwiZXhwIjoxODA2NjQ5NzMwfQ.Nt6Cf2GW6CI46qOOyvmX_QWdpaIIIzVsxq8xICOhfYk	t	2026-04-02 12:38:50.614792+05:30	2027-04-02 12:38:50.614658+05:30	f45d492d-d3c5-41d6-bc70-7f6fbe3da407	2026-04-02 12:38:50.58877+05:30	2026-04-02 12:38:50.58877+05:30
c6ea3be9-bebe-445c-bf0d-e45ae9c0dbcf	PBN-CRD-7507	\N	t	2026-04-02 13:56:02.195961+05:30	\N	d9618e90-c5dc-413c-aec1-1da531dc0095	2026-04-02 13:56:02.195961+05:30	2026-04-02 13:56:02.195961+05:30
abe2f7f5-8699-46a1-8216-6fa157d02d57	PBN-CRD-9228	\N	t	2026-04-02 13:56:32.854892+05:30	\N	ad55f7cb-4859-4e00-a6f5-4025af878f8b	2026-04-02 13:56:32.854892+05:30	2026-04-02 13:56:32.854892+05:30
084c432a-251a-4542-ad8d-16d9940e47ce	PBN-CRD-6234	\N	t	2026-04-02 13:57:45.336791+05:30	\N	cceaf70f-0e5b-4455-bb56-d7094eb6fe35	2026-04-02 13:57:45.336791+05:30	2026-04-02 13:57:45.336791+05:30
0f1a8890-bc4d-4d7b-9389-93f37d503b9d	PBN-2025-00001	https://pbn.lk/card/PBN-2025-00001	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	28935085-2791-417b-a5e8-20c638e4625d	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
4271c0e4-5222-45fc-961a-76c6c068deaf	PBN-2025-00002	https://pbn.lk/card/PBN-2025-00002	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	4f041185-0055-4f86-93a6-0adfd85901e7	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
83aec857-8e81-4aeb-9d47-a69c4897e419	PBN-2025-00003	https://pbn.lk/card/PBN-2025-00003	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	6998ce73-4630-46bd-8783-b1eae0ca3571	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
ce0f698b-0e1f-4dd9-a2a0-91996652f2da	PBN-2025-00004	https://pbn.lk/card/PBN-2025-00004	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	e5538aa3-c7ee-4139-b23f-e6314695b79c	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00fd49d0-339d-4284-86a6-c6d1156ce963	PBN-2025-00005	https://pbn.lk/card/PBN-2025-00005	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	6a42abea-a94a-4d47-9ba2-23540b1f3081	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
230de031-45c9-4f19-a070-7140ded10152	PBN-2025-00006	https://pbn.lk/card/PBN-2025-00006	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	afdbb93b-13a6-43e5-bdc9-fe68c752cd17	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
55684eea-92cd-4d39-a003-b03c8f7c038d	PBN-2025-00007	https://pbn.lk/card/PBN-2025-00007	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	89e6f953-51a2-46ab-8751-f7d13f4e39be	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00ebbe6e-14c5-4d70-9156-e42221938b98	PBN-2025-00008	https://pbn.lk/card/PBN-2025-00008	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	31c98e3c-8b8a-42b0-a3e7-202492c11cdb	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1cc2f625-1ba8-49de-9394-511deacf372e	PBN-2025-00009	https://pbn.lk/card/PBN-2025-00009	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	de39a4f0-abe0-4c96-ad58-0c73fc1b76f1	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1d26e609-7d57-48f5-86f0-5610fb3b3918	PBN-2025-00010	https://pbn.lk/card/PBN-2025-00010	t	2026-04-04 07:38:16.343367+05:30	2027-04-04 07:38:16.343367+05:30	81c3e909-76aa-4e27-8fa0-d261c3f09391	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
1f31b86e-5ada-4b13-bed2-e9b3c3d350da	PBN5975999	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjYXJkX251bWJlciI6IlBCTjU5NzU5OTkiLCJ1c2VyX2lkIjoiMWYzMWI4NmUtNWFkYS00YjEzLWJlZDItZTliM2MzZDM1MGRhIiwiZXhwIjoxODA3MDc2OTU5fQ.ifCYeQuxCOSRrvqE96bOCvPHtW64KUf8Es73SpTTrvE	t	2026-04-07 11:19:19.594603+05:30	2027-04-07 11:19:19.594245+05:30	4e984de5-5efa-4868-8698-05d16de26058	2026-04-07 11:19:19.56823+05:30	2026-04-07 11:19:19.56823+05:30
\.


--
-- Data for Name: redemption_tokens; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.redemption_tokens (offer_id, user_id, token, status, expires_at, signer_name, signature_data, confirmed_at, id, created_at, updated_at) FROM stdin;
ac76180c-f738-4265-b5d4-451d56186df2	8dd6b091-4eb1-42b8-9865-b20d538908f1	4efd078f-46d8-4a01-976a-20be63e93c27	CONFIRMED	2026-04-06 17:08:31.064631+05:30	Mohamed Musni	data:image/png;base64,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	2026-04-06 17:03:49.202982+05:30	924f5821-d812-4ca7-b36e-85c618911431	2026-04-06 16:53:31.018733+05:30	2026-04-06 17:03:49.208001+05:30
09003cd2-2355-4495-9e1f-387a74babd9a	8dd6b091-4eb1-42b8-9865-b20d538908f1	b1225e0c-cc60-4387-80dd-a7ddbcbf5188	EXPIRED	2026-04-06 17:22:36.46234+05:30	\N	\N	\N	f859ad15-b2b1-4df9-9ff1-876be22d3d76	2026-04-06 17:07:36.352736+05:30	2026-04-06 17:22:38.899927+05:30
\.


--
-- Data for Name: referral_status_history; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.referral_status_history (referral_id, old_status, new_status, notes, changed_by, id, created_at, updated_at) FROM stdin;
e1de9a69-449a-433b-ba92-daba2b173244		submitted	Referral created	57bfddaf-c732-4d08-9487-b4d23ab0c9be	1f5b01ed-67ce-462e-8686-1ad398d2a766	2026-04-02 13:30:42.398033+05:30	2026-04-02 13:30:42.398033+05:30
8b729d1e-d31f-4419-bda2-e6d52aa3ccea		submitted	Referral created	b530c068-8d87-47b4-8db6-983d86ba9770	5ba405ab-b149-4d2f-8db3-2895a9589af8	2026-04-02 13:32:06.273924+05:30	2026-04-02 13:32:06.273924+05:30
8b729d1e-d31f-4419-bda2-e6d52aa3ccea	submitted	contacted	Status updated to contacted	ef668beb-ba11-411f-aa5f-114a5816db77	a7a6b733-a0b9-414f-91a4-348519664413	2026-04-02 13:32:14.473944+05:30	2026-04-02 13:32:14.473944+05:30
\.


--
-- Data for Name: referrals; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.referrals (from_member_id, to_member_id, client_name, client_phone, client_email, description, estimated_value, actual_value, status, closed_at, id, created_at, updated_at) FROM stdin;
57bfddaf-c732-4d08-9487-b4d23ab0c9be	dbdf7cfe-4b85-4e9f-b465-a3108291d343	Test Lead	0771231234	\N	\N	\N	\N	submitted	\N	e1de9a69-449a-433b-ba92-daba2b173244	2026-04-02 13:30:42.398033+05:30	2026-04-02 13:30:42.398033+05:30
b530c068-8d87-47b4-8db6-983d86ba9770	ef668beb-ba11-411f-aa5f-114a5816db77	Test Lead	0771231234	\N	\N	\N	\N	contacted	\N	8b729d1e-d31f-4419-bda2-e6d52aa3ccea	2026-04-02 13:32:06.273924+05:30	2026-04-02 13:32:14.478521+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C0	077999999	\N	\N	5000.00	5000.00	closed_won	\N	d0fb6a50-8a6c-471c-a04b-b33569ca6202	2026-04-02 14:14:13.391771+05:30	2026-04-02 14:14:13.391771+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C1	077999999	\N	\N	5000.00	5000.00	closed_won	\N	a1a6fb5e-81b6-41ed-bcf0-80760232e5f3	2026-04-02 14:14:13.391771+05:30	2026-04-02 14:14:13.391771+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C2	077999999	\N	\N	5000.00	5000.00	closed_won	\N	a04e89e5-7c80-4d3d-bdc4-070cb138904f	2026-04-02 14:14:13.391771+05:30	2026-04-02 14:14:13.391771+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C0	077999999	\N	\N	5000.00	5000.00	closed_won	\N	968bc503-2cf6-452a-bf10-86291a9c65c0	2026-04-02 14:16:10.662399+05:30	2026-04-02 14:16:10.662399+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C1	077999999	\N	\N	5000.00	5000.00	closed_won	\N	68cce879-1418-430e-a6da-92aa46c8416d	2026-04-02 14:16:10.662399+05:30	2026-04-02 14:16:10.662399+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C2	077999999	\N	\N	5000.00	5000.00	closed_won	\N	d2d598bc-baea-4d1e-9e42-233b948126ba	2026-04-02 14:16:10.662399+05:30	2026-04-02 14:16:10.662399+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C0	077999999	\N	\N	5000.00	5000.00	closed_won	\N	989afbdd-8d0b-4227-91a4-fd3fec888b26	2026-04-02 14:17:50.164746+05:30	2026-04-02 14:17:50.164746+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C1	077999999	\N	\N	5000.00	5000.00	closed_won	\N	e3d485e9-ef6c-4acb-aaf1-f5df279fe5bc	2026-04-02 14:17:50.164746+05:30	2026-04-02 14:17:50.164746+05:30
8af70fa5-c611-401a-829a-5f3b95925c13	031f068b-729c-4f98-981f-ce1219d9fd8a	C2	077999999	\N	\N	5000.00	5000.00	closed_won	\N	d6d2e058-ef51-4f56-86e0-7e4826d1fa18	2026-04-02 14:17:50.164746+05:30	2026-04-02 14:17:50.164746+05:30
0f1a8890-bc4d-4d7b-9389-93f37d503b9d	4271c0e4-5222-45fc-961a-76c6c068deaf	Kamal Gunawardena	+94771112233	kamal@gmail.com	Needs a property valuation	5000000.00	\N	submitted	\N	86760d93-4412-4559-914f-abf3959d361e	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
4271c0e4-5222-45fc-961a-76c6c068deaf	0f1a8890-bc4d-4d7b-9389-93f37d503b9d	Dinesh Pathirana	+94771113344	dinesh@gmail.com	Software system for hotel	2500000.00	\N	contacted	\N	db49fe0c-37dd-41d4-bf0f-b1240f14af53	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
83aec857-8e81-4aeb-9d47-a69c4897e419	00fd49d0-339d-4284-86a6-c6d1156ce963	Samantha Peris	+94771114455	sam@gmail.com	Financial advisory needed	1000000.00	\N	meeting_scheduled	\N	904bb836-0cd3-4f7c-9661-bbd5f6e7466d	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
ce0f698b-0e1f-4dd9-a2a0-91996652f2da	83aec857-8e81-4aeb-9d47-a69c4897e419	Anoma Ratnayake	+94771115566	anoma@gmail.com	Employee health checkups	750000.00	500000.00	closed_won	2026-04-04 07:38:16.343367+05:30	71991bd8-cc22-43a9-a4bd-46c7c7edc600	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
230de031-45c9-4f19-a070-7140ded10152	55684eea-92cd-4d39-a003-b03c8f7c038d	Prasad Wijesinghe	+94771116677	prasad@gmail.com	E-commerce website design	3000000.00	\N	submitted	\N	84da21ca-4608-45a6-8253-6ef78626596b	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
00ebbe6e-14c5-4d70-9156-e42221938b98	1d26e609-7d57-48f5-86f0-5610fb3b3918	Ruwani Fernando	+94771117788	ruwani@gmail.com	Social media marketing	800000.00	\N	contacted	\N	05e98551-6ebc-4036-97da-2e4b87c453a5	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30
0f1a8890-bc4d-4d7b-9389-93f37d503b9d	4271c0e4-5222-45fc-961a-76c6c068deaf	Kamal Gunawardena	+94771112233	kamal@gmail.com	Needs a property valuation	5000000.00	\N	submitted	\N	3780647a-5f3f-486c-b8f9-876e514e52c0	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
4271c0e4-5222-45fc-961a-76c6c068deaf	0f1a8890-bc4d-4d7b-9389-93f37d503b9d	Dinesh Pathirana	+94771113344	dinesh@gmail.com	Software system for hotel	2500000.00	\N	contacted	\N	15b8325c-112a-4fad-97a4-6a1dbbff500d	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
83aec857-8e81-4aeb-9d47-a69c4897e419	00fd49d0-339d-4284-86a6-c6d1156ce963	Samantha Peris	+94771114455	sam@gmail.com	Financial advisory needed	1000000.00	\N	meeting_scheduled	\N	7a5d4708-5dd2-4292-925f-0dd70a76e6a5	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
ce0f698b-0e1f-4dd9-a2a0-91996652f2da	83aec857-8e81-4aeb-9d47-a69c4897e419	Anoma Ratnayake	+94771115566	anoma@gmail.com	Employee health checkups	750000.00	500000.00	closed_won	2026-04-04 07:38:28.932648+05:30	38af8887-d259-425d-9881-28ebc15a1930	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
230de031-45c9-4f19-a070-7140ded10152	55684eea-92cd-4d39-a003-b03c8f7c038d	Prasad Wijesinghe	+94771116677	prasad@gmail.com	E-commerce website design	3000000.00	\N	submitted	\N	8e6d96fe-383c-4313-b434-572ae5cc09ae	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
00ebbe6e-14c5-4d70-9156-e42221938b98	1d26e609-7d57-48f5-86f0-5610fb3b3918	Ruwani Fernando	+94771117788	ruwani@gmail.com	Social media marketing	800000.00	\N	contacted	\N	1f96885d-268f-4bdb-9b29-d9ad0042daec	2026-04-04 07:38:28.932648+05:30	2026-04-04 07:38:28.932648+05:30
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: pbn_user
--

COPY public.users (phone_number, email, full_name, role, is_active, fcm_token, id, created_at, updated_at, password_hash) FROM stdin;
+94771234567	admin@pbn.lk	Musny Admin	SUPER_ADMIN	t	\N	1f31b86e-5ada-4b13-bed2-e9b3c3d350da	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001001	ashan@pbn.lk	Ashan Fernando	MEMBER	t	\N	0f1a8890-bc4d-4d7b-9389-93f37d503b9d	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001002	nimal@pbn.lk	Nimal Perera	MEMBER	t	\N	4271c0e4-5222-45fc-961a-76c6c068deaf	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001003	kumari@pbn.lk	Kumari Silva	MEMBER	t	\N	83aec857-8e81-4aeb-9d47-a69c4897e419	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001004	roshan@pbn.lk	Roshan Jayasinghe	MEMBER	t	\N	ce0f698b-0e1f-4dd9-a2a0-91996652f2da	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001005	dilani@pbn.lk	Dilani Wickramasinghe	MEMBER	t	\N	00fd49d0-339d-4284-86a6-c6d1156ce963	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001006	suresh@pbn.lk	Suresh Rajapaksa	MEMBER	t	\N	230de031-45c9-4f19-a070-7140ded10152	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001007	lakmal@pbn.lk	Lakmal Bandara	MEMBER	t	\N	55684eea-92cd-4d39-a003-b03c8f7c038d	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001008	priyanka@pbn.lk	Priyanka Gunawardena	MEMBER	t	\N	00ebbe6e-14c5-4d70-9156-e42221938b98	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001009	chathura@pbn.lk	Chathura de Mel	MEMBER	t	\N	1cc2f625-1ba8-49de-9394-511deacf372e	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94772001010	sanduni@pbn.lk	Sanduni Rathnayake	MEMBER	t	\N	1d26e609-7d57-48f5-86f0-5610fb3b3918	2026-04-04 07:38:16.343367+05:30	2026-04-04 07:38:16.343367+05:30	$2b$12$6HyS1DIgfvKWtCOswQnW7OXTM9P9xsEKd2Pe2ixwkWpbaXGhdNwZm
+94770000100	hiltoncolombo@pbn.lk	Hilton Colombo Admin	PARTNER_ADMIN	t	\N	cfd80713-e8e8-4a00-abf8-29ff9135096a	2026-04-06 17:48:15.035911+05:30	2026-04-07 09:31:01.991925+05:30	$2b$12$6pTQwpnqP5Q000E9qSo6VeWloiYsfuZkUycxO8/MfePumzj.HKSLa
+94770000101	softlogicholdings@pbn.lk	Softlogic Holdings Admin	PARTNER_ADMIN	t	\N	10ffb73c-4cc4-4706-9f47-21819fb0a24c	2026-04-06 17:48:15.035911+05:30	2026-04-07 09:31:02.009797+05:30	$2b$12$6pTQwpnqP5Q000E9qSo6VeWloiYsfuZkUycxO8/MfePumzj.HKSLa
+94770000102	spaceylon@pbn.lk	Spa Ceylon Admin	PARTNER_ADMIN	t	\N	5fa4a3ea-e214-4c7a-9ce0-8f9fb71b07ec	2026-04-06 17:48:15.035911+05:30	2026-04-07 09:31:02.012335+05:30	$2b$12$6pTQwpnqP5Q000E9qSo6VeWloiYsfuZkUycxO8/MfePumzj.HKSLa
+94770000103	dialogaxiata@pbn.lk	Dialog Axiata Admin	PARTNER_ADMIN	t	\N	1b09fbbb-5165-4478-bdf8-88243df43273	2026-04-06 17:48:15.035911+05:30	2026-04-07 09:31:02.01465+05:30	$2b$12$6pTQwpnqP5Q000E9qSo6VeWloiYsfuZkUycxO8/MfePumzj.HKSLa
+94770000104	softlogicholdings@pbn.lk	Softlogic Holdings Admin	PARTNER_ADMIN	t	\N	8ec8681b-6029-4a3b-a1cb-bc5bbd164c19	2026-04-06 17:48:15.035911+05:30	2026-04-07 09:31:02.016349+05:30	$2b$12$6pTQwpnqP5Q000E9qSo6VeWloiYsfuZkUycxO8/MfePumzj.HKSLa
+94770000105	spaceylon@pbn.lk	Spa Ceylon Admin	PARTNER_ADMIN	t	\N	a4ad94ae-cede-4d98-a890-40acb26bf51a	2026-04-06 17:48:15.035911+05:30	2026-04-07 09:31:02.017943+05:30	$2b$12$6pTQwpnqP5Q000E9qSo6VeWloiYsfuZkUycxO8/MfePumzj.HKSLa
+94770000106	dialogaxiata@pbn.lk	Dialog Axiata Admin	PARTNER_ADMIN	t	\N	777702ba-5b43-4388-89f7-797cb3f3b043	2026-04-06 17:48:15.035911+05:30	2026-04-07 09:31:02.019491+05:30	$2b$12$6pTQwpnqP5Q000E9qSo6VeWloiYsfuZkUycxO8/MfePumzj.HKSLa
+94775220501	\N	Super Admin	SUPER_ADMIN	t	\N	d277b254-ffc3-4399-84fc-95fa2ea9bd7a	2026-04-02 16:47:41.452366+05:30	2026-04-02 16:47:41.452366+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778811287	\N	Referrer User	MEMBER	t	\N	09479f7e-cde2-4579-a192-e1f7ed34e03f	2026-04-02 12:45:56.909684+05:30	2026-04-02 12:45:56.909684+05:30	$2b$12$fDb3hMVBgZGts/iQgOtp0uBMTOCAWkWuD4CBYx2c.ClvaYL.QJE0u
+94775220502	\N	Test Member	MEMBER	t	\N	b6e4728c-9740-4912-9321-e2f36eaf1c64	2026-04-02 16:47:41.452366+05:30	2026-04-02 16:48:04.823054+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94770000001	admin@pbn.lk	Super Admin	SUPER_ADMIN	t	\N	15c59f4c-0e12-4451-9bed-6edfe7109429	2026-04-04 11:16:03.555577+05:30	2026-04-04 11:16:03.555577+05:30	$2b$12$DZIYnGWvZOrLO7qUjdOOE.851XjCQS7ya3m0EqagZtXnSmXPfs2IS
+94776543210	\N		PROSPECT	t	\N	c9165538-c090-4aa7-a11a-8df1e36d7e0b	2026-04-02 12:14:54.667353+05:30	2026-04-02 12:14:54.667353+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947731065772	\N	Pay Admin	SUPER_ADMIN	t	\N	b37fd9f8-9c0b-46dd-b4a2-d429625c3f42	2026-04-02 14:24:54.523916+05:30	2026-04-02 14:24:54.523916+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947732065772	\N	Pay Member	MEMBER	t	\N	45b0f3cb-b029-4892-a64b-315483f69266	2026-04-02 14:24:54.523916+05:30	2026-04-02 14:24:54.523916+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947731051894	\N	Pay Admin	SUPER_ADMIN	t	\N	dd27fef5-afc9-496f-877b-7b8526af291b	2026-04-02 14:26:10.655675+05:30	2026-04-02 14:26:10.655675+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947732051894	\N	Pay Member	MEMBER	t	\N	06e5e48d-8158-432c-986a-eeb70586154d	2026-04-02 14:26:10.655675+05:30	2026-04-02 14:26:10.655675+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94773761046	kamal@kp.lk	Kamal Perera	MEMBER	t	\N	f636cfef-f7c7-4867-91c7-fd060d0060bc	2026-04-02 12:37:02.910769+05:30	2026-04-02 12:37:02.910769+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94779888888	\N		PROSPECT	t	\N	cfca1177-dd73-43fd-8597-2072532e2815	2026-04-02 14:26:53.595638+05:30	2026-04-02 14:26:53.595638+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94770000000	\N	Super Admin	SUPER_ADMIN	t	\N	a6f44efe-6fa7-4dd4-91b9-60f28ca3ba7b	2026-04-02 12:28:08.528293+05:30	2026-04-02 12:28:08.528293+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94773632973	kamal@kp.lk	Kamal Perera	MEMBER	t	\N	d3de2ba1-af1a-46d4-bcc7-5314de50d90b	2026-04-02 12:38:50.58877+05:30	2026-04-02 12:38:50.58877+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778456153	\N	Kandy Admin	SUPER_ADMIN	t	\N	a563e74e-3ce3-4a8a-86d3-6b6b707dcd9a	2026-04-02 12:42:25.241582+05:30	2026-04-02 12:42:25.241582+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778288356	\N	Target User	MEMBER	t	\N	0475af4a-f113-4135-b503-9c6f7861302b	2026-04-02 12:45:56.909684+05:30	2026-04-02 12:45:56.909684+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778923651	\N	Referrer User	MEMBER	t	\N	7339a815-908c-4ead-92be-1c15cde683d7	2026-04-02 12:48:18.800276+05:30	2026-04-02 12:48:18.800276+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778392331	\N	Target User	MEMBER	t	\N	6daebf4b-ca2c-409a-a5a8-d2e0c2728d15	2026-04-02 12:48:18.800276+05:30	2026-04-02 12:48:18.800276+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778724020	\N	Referrer User	MEMBER	t	\N	902d74a4-3e17-457d-9f3d-124260f71574	2026-04-02 12:49:15.537458+05:30	2026-04-02 12:49:15.537458+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778558985	\N	Target User	MEMBER	t	\N	6eeb2f17-547c-458a-89e9-77964b53d931	2026-04-02 12:49:15.537458+05:30	2026-04-02 12:49:15.537458+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778620770	\N	Referrer User	MEMBER	t	\N	a524ac0e-600c-43dd-a63e-a278b928b41a	2026-04-02 12:54:00.240135+05:30	2026-04-02 12:54:00.240135+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778591712	\N	Target User	MEMBER	t	\N	dd996571-0910-49a7-9c4a-6709cff0b30f	2026-04-02 12:54:00.240135+05:30	2026-04-02 12:54:00.240135+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778301956	\N	Referrer User	MEMBER	t	\N	aae4e11f-7a98-47cb-beb1-ced23ad032f5	2026-04-02 12:55:50.414763+05:30	2026-04-02 12:55:50.414763+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778773955	\N	Target User	MEMBER	t	\N	d28435b8-cf45-4cea-81c9-2f6bb16a987a	2026-04-02 12:55:50.414763+05:30	2026-04-02 12:55:50.414763+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778450345	\N	Referrer User	MEMBER	t	\N	fcaf2acd-d0c9-4827-ac3f-b2295d4ed300	2026-04-02 12:58:01.568452+05:30	2026-04-02 12:58:01.568452+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778390157	\N	Target User	MEMBER	t	\N	a2742b16-52b6-4ba3-8dd3-94d86a92953c	2026-04-02 12:58:01.568452+05:30	2026-04-02 12:58:01.568452+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778580360	\N	Referrer User	MEMBER	t	\N	57885ada-99e3-486a-9ca4-fa22e1df1297	2026-04-02 12:59:33.744639+05:30	2026-04-02 12:59:33.744639+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778425605	\N	Target User	MEMBER	t	\N	84bb9b1e-efe5-44ce-ba9c-7f69b62d39e3	2026-04-02 12:59:33.744639+05:30	2026-04-02 12:59:33.744639+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778770113	\N	Referrer User	MEMBER	t	\N	d2e1abbc-86ff-4614-b80a-95db284a817e	2026-04-02 13:28:28.992205+05:30	2026-04-02 13:28:28.992205+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778898995	\N	Target User	MEMBER	t	\N	0d63ecdf-3470-484e-89f9-f271c38781a3	2026-04-02 13:28:28.992205+05:30	2026-04-02 13:28:28.992205+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778384895	\N	Referrer User	MEMBER	t	\N	57bfddaf-c732-4d08-9487-b4d23ab0c9be	2026-04-02 13:30:25.162248+05:30	2026-04-02 13:30:25.162248+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778905961	\N	Target User	MEMBER	t	\N	dbdf7cfe-4b85-4e9f-b465-a3108291d343	2026-04-02 13:30:25.162248+05:30	2026-04-02 13:30:25.162248+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778969861	\N	Referrer User	MEMBER	t	\N	b530c068-8d87-47b4-8db6-983d86ba9770	2026-04-02 13:31:48.767132+05:30	2026-04-02 13:31:48.767132+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778140869	\N	Target User	MEMBER	t	\N	ef668beb-ba11-411f-aa5f-114a5816db77	2026-04-02 13:31:48.767132+05:30	2026-04-02 13:31:48.767132+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778764461	\N	Event Admin	CHAPTER_ADMIN	t	\N	06f088fc-712a-43c2-acd7-769da035915d	2026-04-02 13:41:55.090806+05:30	2026-04-02 13:41:55.090806+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778570843	\N	Event Member	MEMBER	t	\N	8ece71b2-637f-45c3-9944-5e7b8c9bede5	2026-04-02 13:41:55.090806+05:30	2026-04-02 13:41:55.090806+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778645083	\N	Event Admin	CHAPTER_ADMIN	t	\N	5b445643-5d3c-43ea-9ef2-9af6b6ecddc7	2026-04-02 13:46:53.999445+05:30	2026-04-02 13:46:53.999445+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778756916	\N	Event Member	MEMBER	t	\N	38f8b6f2-6c9c-4079-806c-c872dc190b52	2026-04-02 13:46:53.999445+05:30	2026-04-02 13:46:53.999445+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778547481	\N	Event Admin	CHAPTER_ADMIN	t	\N	ee37bc2b-cbb5-4a63-b489-9a9cd9e38bba	2026-04-02 13:48:58.868832+05:30	2026-04-02 13:48:58.868832+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778643191	\N	Event Member	MEMBER	t	\N	8ec716a9-b55e-4b46-82a4-ec076d7238ca	2026-04-02 13:48:58.868832+05:30	2026-04-02 13:48:58.868832+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778952226	\N	Event Admin	CHAPTER_ADMIN	t	\N	95805690-eb07-42bc-bf2a-645261d928af	2026-04-02 13:50:36.506869+05:30	2026-04-02 13:50:36.506869+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778425878	\N	Event Member	MEMBER	t	\N	a7bc50cc-b0fd-4c9e-91bd-6004e76235bf	2026-04-02 13:50:36.506869+05:30	2026-04-02 13:50:36.506869+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778609381	\N	Rewards Admin	CHAPTER_ADMIN	t	\N	cafe7442-cdc0-46fa-96f6-c16b0d1c0d22	2026-04-02 13:56:02.195961+05:30	2026-04-02 13:56:02.195961+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778979373	\N	Rewards Member	MEMBER	t	\N	c6ea3be9-bebe-445c-bf0d-e45ae9c0dbcf	2026-04-02 13:56:02.195961+05:30	2026-04-02 13:56:02.195961+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778837399	\N	Rewards Admin	CHAPTER_ADMIN	t	\N	8dd6b091-4eb1-42b8-9865-b20d538908f1	2026-04-02 13:56:32.854892+05:30	2026-04-02 13:56:32.854892+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778966320	\N	Rewards Member	MEMBER	t	\N	abe2f7f5-8699-46a1-8216-6fa157d02d57	2026-04-02 13:56:32.854892+05:30	2026-04-02 13:56:32.854892+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778833910	\N	Rewards Admin	CHAPTER_ADMIN	t	\N	3255c45d-64e3-4302-9525-de2cef1a8c1e	2026-04-02 13:57:45.336791+05:30	2026-04-02 13:57:45.336791+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94778344478	\N	Rewards Member	MEMBER	t	\N	084c432a-251a-4542-ad8d-16d9940e47ce	2026-04-02 13:57:45.336791+05:30	2026-04-02 13:57:45.336791+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776364599	\N	Analytics Admin	SUPER_ADMIN	t	\N	7b28011f-06fe-4dbd-8615-c487c71aca08	2026-04-02 14:11:02.831493+05:30	2026-04-02 14:11:02.831493+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776958881	\N	Analytic User	MEMBER	t	\N	17392d12-b0de-4a40-bfa2-8828a2f30ab6	2026-04-02 14:11:02.831493+05:30	2026-04-02 14:11:02.831493+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776104384	\N	Analytic User	MEMBER	t	\N	33ba4dfb-6940-44b7-ba79-d96e092e2350	2026-04-02 14:11:02.831493+05:30	2026-04-02 14:11:02.831493+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776792138	\N	Analytics Admin	SUPER_ADMIN	t	\N	8708a2a5-cc11-42e1-bc0c-0b77f5bb53b3	2026-04-02 14:11:24.923231+05:30	2026-04-02 14:11:24.923231+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776745180	\N	Analytic User	MEMBER	t	\N	066de981-80b2-466a-b5be-02d0a9481c20	2026-04-02 14:11:24.923231+05:30	2026-04-02 14:11:24.923231+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776193077	\N	Analytic User	MEMBER	t	\N	49651388-1984-4d1a-bbe9-d3098adc26df	2026-04-02 14:11:24.923231+05:30	2026-04-02 14:11:24.923231+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776317005	\N	Analytics Admin	SUPER_ADMIN	t	\N	522d5d5f-02c6-454a-ab55-b1fde78787f3	2026-04-02 14:11:57.182685+05:30	2026-04-02 14:11:57.182685+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776472127	\N	Analytic User	MEMBER	t	\N	5d3975f2-d466-4fd6-877d-0ea9df2d141a	2026-04-02 14:11:57.182685+05:30	2026-04-02 14:11:57.182685+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776980745	\N	Analytic User	MEMBER	t	\N	6ec842ee-1e80-46af-a0ff-b8214ef6554f	2026-04-02 14:11:57.182685+05:30	2026-04-02 14:11:57.182685+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776306955	\N	Analytics Admin	SUPER_ADMIN	t	\N	a1395af0-b4ac-4239-acaf-b6c62341d8c9	2026-04-02 14:12:09.322342+05:30	2026-04-02 14:12:09.322342+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776577009	\N	Analytic User	MEMBER	t	\N	d105a65e-1d55-4353-acb7-e7aeac47b860	2026-04-02 14:12:09.322342+05:30	2026-04-02 14:12:09.322342+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94776631256	\N	Analytic User	MEMBER	t	\N	9645b123-7733-4f22-abc4-ee00f9f5925b	2026-04-02 14:12:09.322342+05:30	2026-04-02 14:12:09.322342+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94775000001	\N	Admin Test	SUPER_ADMIN	t	\N	031f068b-729c-4f98-981f-ce1219d9fd8a	2026-04-02 14:14:13.391771+05:30	2026-04-02 14:14:13.391771+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94775000002	\N	Member Test	MEMBER	t	\N	8af70fa5-c611-401a-829a-5f3b95925c13	2026-04-02 14:14:13.391771+05:30	2026-04-02 14:14:13.391771+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947731016660	\N	Pay Admin	SUPER_ADMIN	t	\N	1038e264-8a79-45f9-906a-2179358ce8a4	2026-04-02 14:24:14.979995+05:30	2026-04-02 14:24:14.979995+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947732016660	\N	Pay Member	MEMBER	t	\N	3cac2a2e-d280-4063-8721-eda5834edadc	2026-04-02 14:24:14.979995+05:30	2026-04-02 14:24:14.979995+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947731091070	\N	Pay Admin	SUPER_ADMIN	t	\N	1acf35ac-ef83-4794-ac31-934a3b32a065	2026-04-02 14:27:23.002144+05:30	2026-04-02 14:27:23.002144+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947732091070	\N	Pay Member	MEMBER	t	\N	9704cb54-4902-465a-849a-f48d40fe7457	2026-04-02 14:27:23.002144+05:30	2026-04-02 14:27:23.002144+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947731088726	\N	Pay Admin	SUPER_ADMIN	t	\N	9ac91934-c581-49b6-9559-a5299a7e672c	2026-04-02 14:27:56.580107+05:30	2026-04-02 14:27:56.580107+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947732088726	\N	Pay Member	MEMBER	t	\N	92159ee4-fd32-408b-8130-3b5a178b473e	2026-04-02 14:27:56.580107+05:30	2026-04-02 14:27:56.580107+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947731014258	\N	Pay Admin	SUPER_ADMIN	t	\N	5036dec0-fdce-446c-8a6f-fc3ade8c6809	2026-04-02 14:28:16.470377+05:30	2026-04-02 14:28:16.470377+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+947732014258	\N	Pay Member	MEMBER	t	\N	6c0e4fdc-a0c1-4bea-9002-4a8a0e4aff01	2026-04-02 14:28:16.470377+05:30	2026-04-02 14:28:16.470377+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94773910001	\N	Pay Admin	SUPER_ADMIN	t	\N	619c7510-326d-4a80-bdfc-d337b0e9270b	2026-04-02 14:29:11.018984+05:30	2026-04-02 14:29:11.018984+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94773910002	\N	Pay Member	MEMBER	t	\N	acfb3db2-398f-4a07-9d9f-50d424e242b5	2026-04-02 14:29:11.018984+05:30	2026-04-02 14:29:11.018984+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94773149001	\N	Pay Admin	SUPER_ADMIN	t	\N	a4ecfcfe-e434-4c99-b82d-c3eda7f88a3f	2026-04-02 14:32:09.917284+05:30	2026-04-02 14:32:09.917284+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94773149002	\N	Pay Member	MEMBER	t	\N	8f731352-d499-40f0-bf0f-8fb4783c98ec	2026-04-02 14:32:09.917284+05:30	2026-04-02 14:32:09.917284+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94773231501	\N	Pay Admin	SUPER_ADMIN	t	\N	e90565f0-6d9d-4d1d-83ca-89fd69baf500	2026-04-02 14:33:34.44711+05:30	2026-04-02 14:33:34.44711+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94773231502	\N	Pay Member	MEMBER	t	\N	3508a02a-9721-4b7c-9d8d-90f9e34a8ded	2026-04-02 14:33:34.44711+05:30	2026-04-02 14:33:34.44711+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94774301601	\N	Notif User	MEMBER	t	\N	03fe0ac4-48b6-4b4c-ab29-222471153e6c	2026-04-02 16:37:10.701383+05:30	2026-04-02 16:37:10.701383+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94774702701	\N	Notif User	MEMBER	t	mock-fcm-token-1234	049253b2-932e-4866-b032-38183af662af	2026-04-02 16:38:12.836607+05:30	2026-04-02 16:38:21.707905+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94775717701	\N	Super Admin	SUPER_ADMIN	t	\N	97487004-06f4-435c-8959-8f661040a723	2026-04-02 16:45:52.982026+05:30	2026-04-02 16:45:52.982026+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
+94775717702	\N	Test Member	MEMBER	t	\N	94934609-c4da-4db8-a98c-700015a4ee9b	2026-04-02 16:45:52.982026+05:30	2026-04-02 16:45:52.982026+05:30	$2b$12$hguQY07rIVgH/KDVqGQE4uzx2NNXZfIBu/ccIt7kHXC/irFWYhCuq
\.


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: application_status_history application_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.application_status_history
    ADD CONSTRAINT application_status_history_pkey PRIMARY KEY (id);


--
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: businesses businesses_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_pkey PRIMARY KEY (id);


--
-- Name: chapter_memberships chapter_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.chapter_memberships
    ADD CONSTRAINT chapter_memberships_pkey PRIMARY KEY (id);


--
-- Name: chapters chapters_name_key; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.chapters
    ADD CONSTRAINT chapters_name_key UNIQUE (name);


--
-- Name: chapters chapters_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.chapters
    ADD CONSTRAINT chapters_pkey PRIMARY KEY (id);


--
-- Name: coupon_codes coupon_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.coupon_codes
    ADD CONSTRAINT coupon_codes_pkey PRIMARY KEY (id);


--
-- Name: event_attendance event_attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.event_attendance
    ADD CONSTRAINT event_attendance_pkey PRIMARY KEY (id);


--
-- Name: event_rsvps event_rsvps_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT event_rsvps_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: industry_categories industry_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.industry_categories
    ADD CONSTRAINT industry_categories_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: offer_redemptions offer_redemptions_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.offer_redemptions
    ADD CONSTRAINT offer_redemptions_pkey PRIMARY KEY (id);


--
-- Name: offers offers_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.offers
    ADD CONSTRAINT offers_pkey PRIMARY KEY (id);


--
-- Name: partners partners_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: privilege_cards privilege_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.privilege_cards
    ADD CONSTRAINT privilege_cards_pkey PRIMARY KEY (id);


--
-- Name: privilege_cards privilege_cards_user_id_key; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.privilege_cards
    ADD CONSTRAINT privilege_cards_user_id_key UNIQUE (user_id);


--
-- Name: redemption_tokens redemption_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.redemption_tokens
    ADD CONSTRAINT redemption_tokens_pkey PRIMARY KEY (id);


--
-- Name: referral_status_history referral_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.referral_status_history
    ADD CONSTRAINT referral_status_history_pkey PRIMARY KEY (id);


--
-- Name: referrals referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (id);


--
-- Name: coupon_codes unique_coupon_per_user_offer; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.coupon_codes
    ADD CONSTRAINT unique_coupon_per_user_offer UNIQUE (offer_id, user_id);


--
-- Name: event_rsvps unique_event_rsvp; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT unique_event_rsvp UNIQUE (event_id, user_id);


--
-- Name: chapter_memberships unique_industry_per_chapter; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.chapter_memberships
    ADD CONSTRAINT unique_industry_per_chapter UNIQUE (chapter_id, industry_category_id);


--
-- Name: offer_redemptions unique_offer_redemption; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.offer_redemptions
    ADD CONSTRAINT unique_offer_redemption UNIQUE (offer_id, user_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ix_application_status_history_application_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_application_status_history_application_id ON public.application_status_history USING btree (application_id);


--
-- Name: ix_application_status_history_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_application_status_history_id ON public.application_status_history USING btree (id);


--
-- Name: ix_applications_contact_number; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_applications_contact_number ON public.applications USING btree (contact_number);


--
-- Name: ix_applications_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_applications_id ON public.applications USING btree (id);


--
-- Name: ix_audit_logs_actor_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_audit_logs_actor_id ON public.audit_logs USING btree (actor_id);


--
-- Name: ix_audit_logs_entity_type; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_audit_logs_entity_type ON public.audit_logs USING btree (entity_type);


--
-- Name: ix_audit_logs_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_audit_logs_id ON public.audit_logs USING btree (id);


--
-- Name: ix_businesses_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_businesses_id ON public.businesses USING btree (id);


--
-- Name: ix_businesses_owner_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_businesses_owner_user_id ON public.businesses USING btree (owner_user_id);


--
-- Name: ix_chapter_memberships_chapter_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_chapter_memberships_chapter_id ON public.chapter_memberships USING btree (chapter_id);


--
-- Name: ix_chapter_memberships_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_chapter_memberships_id ON public.chapter_memberships USING btree (id);


--
-- Name: ix_chapter_memberships_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_chapter_memberships_user_id ON public.chapter_memberships USING btree (user_id);


--
-- Name: ix_chapters_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_chapters_id ON public.chapters USING btree (id);


--
-- Name: ix_coupon_codes_code; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE UNIQUE INDEX ix_coupon_codes_code ON public.coupon_codes USING btree (code);


--
-- Name: ix_coupon_codes_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_coupon_codes_id ON public.coupon_codes USING btree (id);


--
-- Name: ix_coupon_codes_offer_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_coupon_codes_offer_id ON public.coupon_codes USING btree (offer_id);


--
-- Name: ix_coupon_codes_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_coupon_codes_user_id ON public.coupon_codes USING btree (user_id);


--
-- Name: ix_event_attendance_event_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_event_attendance_event_id ON public.event_attendance USING btree (event_id);


--
-- Name: ix_event_attendance_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_event_attendance_id ON public.event_attendance USING btree (id);


--
-- Name: ix_event_attendance_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_event_attendance_user_id ON public.event_attendance USING btree (user_id);


--
-- Name: ix_event_rsvps_event_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_event_rsvps_event_id ON public.event_rsvps USING btree (event_id);


--
-- Name: ix_event_rsvps_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_event_rsvps_id ON public.event_rsvps USING btree (id);


--
-- Name: ix_event_rsvps_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_event_rsvps_user_id ON public.event_rsvps USING btree (user_id);


--
-- Name: ix_events_chapter_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_events_chapter_id ON public.events USING btree (chapter_id);


--
-- Name: ix_events_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_events_id ON public.events USING btree (id);


--
-- Name: ix_industry_categories_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_industry_categories_id ON public.industry_categories USING btree (id);


--
-- Name: ix_industry_categories_slug; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE UNIQUE INDEX ix_industry_categories_slug ON public.industry_categories USING btree (slug);


--
-- Name: ix_notifications_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_notifications_id ON public.notifications USING btree (id);


--
-- Name: ix_notifications_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: ix_offer_redemptions_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_offer_redemptions_id ON public.offer_redemptions USING btree (id);


--
-- Name: ix_offer_redemptions_offer_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_offer_redemptions_offer_id ON public.offer_redemptions USING btree (offer_id);


--
-- Name: ix_offer_redemptions_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_offer_redemptions_user_id ON public.offer_redemptions USING btree (user_id);


--
-- Name: ix_offers_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_offers_id ON public.offers USING btree (id);


--
-- Name: ix_offers_partner_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_offers_partner_id ON public.offers USING btree (partner_id);


--
-- Name: ix_partners_admin_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_partners_admin_id ON public.partners USING btree (admin_id);


--
-- Name: ix_partners_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_partners_id ON public.partners USING btree (id);


--
-- Name: ix_payments_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_payments_id ON public.payments USING btree (id);


--
-- Name: ix_payments_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_payments_user_id ON public.payments USING btree (user_id);


--
-- Name: ix_privilege_cards_card_number; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE UNIQUE INDEX ix_privilege_cards_card_number ON public.privilege_cards USING btree (card_number);


--
-- Name: ix_privilege_cards_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_privilege_cards_id ON public.privilege_cards USING btree (id);


--
-- Name: ix_redemption_tokens_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_redemption_tokens_id ON public.redemption_tokens USING btree (id);


--
-- Name: ix_redemption_tokens_offer_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_redemption_tokens_offer_id ON public.redemption_tokens USING btree (offer_id);


--
-- Name: ix_redemption_tokens_token; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE UNIQUE INDEX ix_redemption_tokens_token ON public.redemption_tokens USING btree (token);


--
-- Name: ix_redemption_tokens_user_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_redemption_tokens_user_id ON public.redemption_tokens USING btree (user_id);


--
-- Name: ix_referral_status_history_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_referral_status_history_id ON public.referral_status_history USING btree (id);


--
-- Name: ix_referral_status_history_referral_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_referral_status_history_referral_id ON public.referral_status_history USING btree (referral_id);


--
-- Name: ix_referrals_from_member_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_referrals_from_member_id ON public.referrals USING btree (from_member_id);


--
-- Name: ix_referrals_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_referrals_id ON public.referrals USING btree (id);


--
-- Name: ix_referrals_to_member_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_referrals_to_member_id ON public.referrals USING btree (to_member_id);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_phone_number; Type: INDEX; Schema: public; Owner: pbn_user
--

CREATE UNIQUE INDEX ix_users_phone_number ON public.users USING btree (phone_number);


--
-- Name: application_status_history application_status_history_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.application_status_history
    ADD CONSTRAINT application_status_history_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;


--
-- Name: application_status_history application_status_history_changed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.application_status_history
    ADD CONSTRAINT application_status_history_changed_by_user_id_fkey FOREIGN KEY (changed_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: applications applications_industry_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_industry_category_id_fkey FOREIGN KEY (industry_category_id) REFERENCES public.industry_categories(id);


--
-- Name: audit_logs audit_logs_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: businesses businesses_industry_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_industry_category_id_fkey FOREIGN KEY (industry_category_id) REFERENCES public.industry_categories(id);


--
-- Name: businesses businesses_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.businesses
    ADD CONSTRAINT businesses_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chapter_memberships chapter_memberships_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.chapter_memberships
    ADD CONSTRAINT chapter_memberships_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapters(id) ON DELETE CASCADE;


--
-- Name: chapter_memberships chapter_memberships_industry_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.chapter_memberships
    ADD CONSTRAINT chapter_memberships_industry_category_id_fkey FOREIGN KEY (industry_category_id) REFERENCES public.industry_categories(id);


--
-- Name: chapter_memberships chapter_memberships_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.chapter_memberships
    ADD CONSTRAINT chapter_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: coupon_codes coupon_codes_offer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.coupon_codes
    ADD CONSTRAINT coupon_codes_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.offers(id) ON DELETE CASCADE;


--
-- Name: coupon_codes coupon_codes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.coupon_codes
    ADD CONSTRAINT coupon_codes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: event_attendance event_attendance_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.event_attendance
    ADD CONSTRAINT event_attendance_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: event_attendance event_attendance_marked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.event_attendance
    ADD CONSTRAINT event_attendance_marked_by_fkey FOREIGN KEY (marked_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: event_attendance event_attendance_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.event_attendance
    ADD CONSTRAINT event_attendance_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: event_rsvps event_rsvps_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT event_rsvps_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: event_rsvps event_rsvps_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.event_rsvps
    ADD CONSTRAINT event_rsvps_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: events events_chapter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.chapters(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: offer_redemptions offer_redemptions_offer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.offer_redemptions
    ADD CONSTRAINT offer_redemptions_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.offers(id) ON DELETE CASCADE;


--
-- Name: offer_redemptions offer_redemptions_redemption_token_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.offer_redemptions
    ADD CONSTRAINT offer_redemptions_redemption_token_id_fkey FOREIGN KEY (redemption_token_id) REFERENCES public.redemption_tokens(id) ON DELETE SET NULL;


--
-- Name: offer_redemptions offer_redemptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.offer_redemptions
    ADD CONSTRAINT offer_redemptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: offers offers_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.offers
    ADD CONSTRAINT offers_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES public.partners(id) ON DELETE CASCADE;


--
-- Name: partners partners_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: payments payments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: privilege_cards privilege_cards_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.privilege_cards
    ADD CONSTRAINT privilege_cards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: redemption_tokens redemption_tokens_offer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.redemption_tokens
    ADD CONSTRAINT redemption_tokens_offer_id_fkey FOREIGN KEY (offer_id) REFERENCES public.offers(id) ON DELETE CASCADE;


--
-- Name: redemption_tokens redemption_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.redemption_tokens
    ADD CONSTRAINT redemption_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: referral_status_history referral_status_history_changed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.referral_status_history
    ADD CONSTRAINT referral_status_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: referral_status_history referral_status_history_referral_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.referral_status_history
    ADD CONSTRAINT referral_status_history_referral_id_fkey FOREIGN KEY (referral_id) REFERENCES public.referrals(id) ON DELETE CASCADE;


--
-- Name: referrals referrals_from_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_from_member_id_fkey FOREIGN KEY (from_member_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: referrals referrals_to_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pbn_user
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_to_member_id_fkey FOREIGN KEY (to_member_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict knntWpzktnDbhKEcaJGFIk1G8gFhH8wXanexSNbhnCNfaRAQkS18kg3Ojf74nIj

