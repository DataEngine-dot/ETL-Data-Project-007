--
-- PostgreSQL database dump
--

-- Dumped from database version 13.20
-- Dumped by pg_dump version 13.21 (Ubuntu 13.21-1.pgdg20.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS transaction_sales_order_id_fkey;
ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS transaction_purchase_order_id_fkey;
ALTER TABLE IF EXISTS ONLY public.staff DROP CONSTRAINT IF EXISTS staff_department_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sales_order DROP CONSTRAINT IF EXISTS sales_order_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sales_order DROP CONSTRAINT IF EXISTS sales_order_design_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sales_order DROP CONSTRAINT IF EXISTS sales_order_currency_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sales_order DROP CONSTRAINT IF EXISTS sales_order_counterparty_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sales_order DROP CONSTRAINT IF EXISTS sales_order_agreed_delivery_location_id_fkey;
ALTER TABLE IF EXISTS ONLY public.purchase_order DROP CONSTRAINT IF EXISTS purchase_order_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY public.purchase_order DROP CONSTRAINT IF EXISTS purchase_order_currency_id_fkey;
ALTER TABLE IF EXISTS ONLY public.purchase_order DROP CONSTRAINT IF EXISTS purchase_order_counterparty_id_fkey;
ALTER TABLE IF EXISTS ONLY public.purchase_order DROP CONSTRAINT IF EXISTS purchase_order_agreed_delivery_location_id_fkey;
ALTER TABLE IF EXISTS ONLY public.payment DROP CONSTRAINT IF EXISTS payment_transaction_id_fkey;
ALTER TABLE IF EXISTS ONLY public.payment DROP CONSTRAINT IF EXISTS payment_payment_type_id_fkey;
ALTER TABLE IF EXISTS ONLY public.payment DROP CONSTRAINT IF EXISTS payment_currency_id_fkey;
ALTER TABLE IF EXISTS ONLY public.payment DROP CONSTRAINT IF EXISTS payment_counterparty_id_fkey;
ALTER TABLE IF EXISTS ONLY public.counterparty DROP CONSTRAINT IF EXISTS counterparty_legal_address_id_fkey;
DROP INDEX IF EXISTS public.transaction_sales_order_id_key;
DROP INDEX IF EXISTS public.transaction_purchase_order_id_key;
DROP INDEX IF EXISTS public.payment_transaction_id_key;
ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS transaction_pkey;
ALTER TABLE IF EXISTS ONLY public.staff DROP CONSTRAINT IF EXISTS staff_pkey;
ALTER TABLE IF EXISTS ONLY public.sales_order DROP CONSTRAINT IF EXISTS sales_order_pkey;
ALTER TABLE IF EXISTS ONLY public.purchase_order DROP CONSTRAINT IF EXISTS purchase_order_pkey;
ALTER TABLE IF EXISTS ONLY public.payment_type DROP CONSTRAINT IF EXISTS payment_type_pkey;
ALTER TABLE IF EXISTS ONLY public.payment DROP CONSTRAINT IF EXISTS payment_pkey;
ALTER TABLE IF EXISTS ONLY public.design DROP CONSTRAINT IF EXISTS design_pkey;
ALTER TABLE IF EXISTS ONLY public.department DROP CONSTRAINT IF EXISTS department_pkey;
ALTER TABLE IF EXISTS ONLY public.currency DROP CONSTRAINT IF EXISTS currency_pkey;
ALTER TABLE IF EXISTS ONLY public.counterparty DROP CONSTRAINT IF EXISTS counterparty_pkey;
ALTER TABLE IF EXISTS ONLY public.address DROP CONSTRAINT IF EXISTS address_pkey;
ALTER TABLE IF EXISTS ONLY public._prisma_migrations DROP CONSTRAINT IF EXISTS _prisma_migrations_pkey;
ALTER TABLE IF EXISTS public.transaction ALTER COLUMN transaction_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.staff ALTER COLUMN staff_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.sales_order ALTER COLUMN sales_order_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.purchase_order ALTER COLUMN purchase_order_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.payment_type ALTER COLUMN payment_type_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.payment ALTER COLUMN payment_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.design ALTER COLUMN design_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.department ALTER COLUMN department_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.currency ALTER COLUMN currency_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.counterparty ALTER COLUMN counterparty_id DROP DEFAULT;
ALTER TABLE IF EXISTS public.address ALTER COLUMN address_id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.transaction_transaction_id_seq;
DROP TABLE IF EXISTS public.transaction;
DROP SEQUENCE IF EXISTS public.staff_staff_id_seq;
DROP TABLE IF EXISTS public.staff;
DROP SEQUENCE IF EXISTS public.sales_order_sales_order_id_seq;
DROP TABLE IF EXISTS public.sales_order;
DROP SEQUENCE IF EXISTS public.purchase_order_purchase_order_id_seq;
DROP TABLE IF EXISTS public.purchase_order;
DROP SEQUENCE IF EXISTS public.payment_type_payment_type_id_seq;
DROP TABLE IF EXISTS public.payment_type;
DROP SEQUENCE IF EXISTS public.payment_payment_id_seq;
DROP TABLE IF EXISTS public.payment;
DROP SEQUENCE IF EXISTS public.design_design_id_seq;
DROP TABLE IF EXISTS public.design;
DROP SEQUENCE IF EXISTS public.department_department_id_seq;
DROP TABLE IF EXISTS public.department;
DROP SEQUENCE IF EXISTS public.currency_currency_id_seq;
DROP TABLE IF EXISTS public.currency;
DROP SEQUENCE IF EXISTS public.counterparty_counterparty_id_seq;
DROP TABLE IF EXISTS public.counterparty;
DROP SEQUENCE IF EXISTS public.address_address_id_seq;
DROP TABLE IF EXISTS public.address;
DROP TABLE IF EXISTS public._prisma_migrations;
DROP TYPE IF EXISTS public."TransactionType";
DROP TYPE IF EXISTS public."PaymentTypeName";
--
-- Name: PaymentTypeName; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."PaymentTypeName" AS ENUM (
    'SALES_RECEIPT',
    'SALES_REFUND',
    'PURCHASE_PAYMENT',
    'PURCHASE_REFUND'
);


--
-- Name: TransactionType; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public."TransactionType" AS ENUM (
    'SALE',
    'PURCHASE'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- Name: address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.address (
    address_id integer NOT NULL,
    address_line_1 text NOT NULL,
    address_line_2 text,
    district text,
    city text NOT NULL,
    postal_code text NOT NULL,
    country text NOT NULL,
    phone text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL
);


--
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.address_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: address_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.address_address_id_seq OWNED BY public.address.address_id;


--
-- Name: counterparty; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.counterparty (
    counterparty_id integer NOT NULL,
    counterparty_legal_name text NOT NULL,
    legal_address_id integer NOT NULL,
    commercial_contact text,
    delivery_contact text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL
);


--
-- Name: counterparty_counterparty_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.counterparty_counterparty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: counterparty_counterparty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.counterparty_counterparty_id_seq OWNED BY public.counterparty.counterparty_id;


--
-- Name: currency; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency (
    currency_id integer NOT NULL,
    currency_code character varying(3) NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL
);


--
-- Name: currency_currency_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currency_currency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currency_currency_id_seq OWNED BY public.currency.currency_id;


--
-- Name: department; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.department (
    department_id integer NOT NULL,
    department_name text NOT NULL,
    location text,
    manager text,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL
);


--
-- Name: department_department_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.department_department_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: department_department_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.department_department_id_seq OWNED BY public.department.department_id;


--
-- Name: design; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.design (
    design_id integer NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    design_name text NOT NULL,
    file_location text NOT NULL,
    file_name text NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL
);


--
-- Name: design_design_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.design_design_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: design_design_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.design_design_id_seq OWNED BY public.design.design_id;


--
-- Name: payment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment (
    payment_id integer NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL,
    transaction_id integer NOT NULL,
    counterparty_id integer NOT NULL,
    payment_amount numeric(10,2) NOT NULL,
    currency_id integer NOT NULL,
    payment_type_id integer NOT NULL,
    paid boolean NOT NULL,
    payment_date text NOT NULL,
    company_ac_number integer NOT NULL,
    counterparty_ac_number integer NOT NULL
);


--
-- Name: payment_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_payment_id_seq OWNED BY public.payment.payment_id;


--
-- Name: payment_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_type (
    payment_type_id integer NOT NULL,
    payment_type_name public."PaymentTypeName" NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL
);


--
-- Name: payment_type_payment_type_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.payment_type_payment_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: payment_type_payment_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.payment_type_payment_type_id_seq OWNED BY public.payment_type.payment_type_id;


--
-- Name: purchase_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_order (
    purchase_order_id integer NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL,
    staff_id integer NOT NULL,
    counterparty_id integer NOT NULL,
    item_code text NOT NULL,
    item_quantity integer NOT NULL,
    item_unit_price numeric(10,2) NOT NULL,
    currency_id integer NOT NULL,
    agreed_delivery_date text NOT NULL,
    agreed_payment_date text NOT NULL,
    agreed_delivery_location_id integer NOT NULL
);


--
-- Name: purchase_order_purchase_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.purchase_order_purchase_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: purchase_order_purchase_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.purchase_order_purchase_order_id_seq OWNED BY public.purchase_order.purchase_order_id;


--
-- Name: sales_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_order (
    sales_order_id integer NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL,
    design_id integer NOT NULL,
    staff_id integer NOT NULL,
    counterparty_id integer NOT NULL,
    units_sold integer NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    currency_id integer NOT NULL,
    agreed_delivery_date text NOT NULL,
    agreed_payment_date text NOT NULL,
    agreed_delivery_location_id integer NOT NULL
);


--
-- Name: sales_order_sales_order_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_order_sales_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_order_sales_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_order_sales_order_id_seq OWNED BY public.sales_order.sales_order_id;


--
-- Name: staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff (
    staff_id integer NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    department_id integer NOT NULL,
    email_address text NOT NULL,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL
);


--
-- Name: staff_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_staff_id_seq OWNED BY public.staff.staff_id;


--
-- Name: transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction (
    transaction_id integer NOT NULL,
    transaction_type public."TransactionType" NOT NULL,
    sales_order_id integer,
    purchase_order_id integer,
    created_at timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_updated timestamp(3) without time zone NOT NULL
);


--
-- Name: transaction_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_transaction_id_seq OWNED BY public.transaction.transaction_id;


--
-- Name: address address_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.address ALTER COLUMN address_id SET DEFAULT nextval('public.address_address_id_seq'::regclass);


--
-- Name: counterparty counterparty_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.counterparty ALTER COLUMN counterparty_id SET DEFAULT nextval('public.counterparty_counterparty_id_seq'::regclass);


--
-- Name: currency currency_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency ALTER COLUMN currency_id SET DEFAULT nextval('public.currency_currency_id_seq'::regclass);


--
-- Name: department department_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department ALTER COLUMN department_id SET DEFAULT nextval('public.department_department_id_seq'::regclass);


--
-- Name: design design_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.design ALTER COLUMN design_id SET DEFAULT nextval('public.design_design_id_seq'::regclass);


--
-- Name: payment payment_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment ALTER COLUMN payment_id SET DEFAULT nextval('public.payment_payment_id_seq'::regclass);


--
-- Name: payment_type payment_type_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_type ALTER COLUMN payment_type_id SET DEFAULT nextval('public.payment_type_payment_type_id_seq'::regclass);


--
-- Name: purchase_order purchase_order_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order ALTER COLUMN purchase_order_id SET DEFAULT nextval('public.purchase_order_purchase_order_id_seq'::regclass);


--
-- Name: sales_order sales_order_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order ALTER COLUMN sales_order_id SET DEFAULT nextval('public.sales_order_sales_order_id_seq'::regclass);


--
-- Name: staff staff_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff ALTER COLUMN staff_id SET DEFAULT nextval('public.staff_staff_id_seq'::regclass);


--
-- Name: transaction transaction_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction ALTER COLUMN transaction_id SET DEFAULT nextval('public.transaction_transaction_id_seq'::regclass);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);


--
-- Name: counterparty counterparty_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.counterparty
    ADD CONSTRAINT counterparty_pkey PRIMARY KEY (counterparty_id);


--
-- Name: currency currency_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (currency_id);


--
-- Name: department department_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (department_id);


--
-- Name: design design_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.design
    ADD CONSTRAINT design_pkey PRIMARY KEY (design_id);


--
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- Name: payment_type payment_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_type
    ADD CONSTRAINT payment_type_pkey PRIMARY KEY (payment_type_id);


--
-- Name: purchase_order purchase_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_pkey PRIMARY KEY (purchase_order_id);


--
-- Name: sales_order sales_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_pkey PRIMARY KEY (sales_order_id);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (staff_id);


--
-- Name: transaction transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (transaction_id);


--
-- Name: payment_transaction_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payment_transaction_id_key ON public.payment USING btree (transaction_id);


--
-- Name: transaction_purchase_order_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX transaction_purchase_order_id_key ON public.transaction USING btree (purchase_order_id);


--
-- Name: transaction_sales_order_id_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX transaction_sales_order_id_key ON public.transaction USING btree (sales_order_id);


--
-- Name: counterparty counterparty_legal_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.counterparty
    ADD CONSTRAINT counterparty_legal_address_id_fkey FOREIGN KEY (legal_address_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: payment payment_counterparty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_counterparty_id_fkey FOREIGN KEY (counterparty_id) REFERENCES public.counterparty(counterparty_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: payment payment_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currency(currency_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: payment payment_payment_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_payment_type_id_fkey FOREIGN KEY (payment_type_id) REFERENCES public.payment_type(payment_type_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: payment payment_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transaction(transaction_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: purchase_order purchase_order_agreed_delivery_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_agreed_delivery_location_id_fkey FOREIGN KEY (agreed_delivery_location_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: purchase_order purchase_order_counterparty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_counterparty_id_fkey FOREIGN KEY (counterparty_id) REFERENCES public.counterparty(counterparty_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: purchase_order purchase_order_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currency(currency_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: purchase_order purchase_order_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.purchase_order
    ADD CONSTRAINT purchase_order_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: sales_order sales_order_agreed_delivery_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_agreed_delivery_location_id_fkey FOREIGN KEY (agreed_delivery_location_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: sales_order sales_order_counterparty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_counterparty_id_fkey FOREIGN KEY (counterparty_id) REFERENCES public.counterparty(counterparty_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: sales_order sales_order_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currency(currency_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: sales_order sales_order_design_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_design_id_fkey FOREIGN KEY (design_id) REFERENCES public.design(design_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: sales_order sales_order_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_order
    ADD CONSTRAINT sales_order_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: staff staff_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: transaction transaction_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES public.purchase_order(purchase_order_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: transaction transaction_sales_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_sales_order_id_fkey FOREIGN KEY (sales_order_id) REFERENCES public.sales_order(sales_order_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

