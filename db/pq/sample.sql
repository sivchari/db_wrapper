set client_encoding = 'UTF8';

create table sample (
  id serial primary key,
  age integer not null,
  ja_name varchar not null,
  en_name varchar not null
);