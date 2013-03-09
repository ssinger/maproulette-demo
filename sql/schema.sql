begin;

create table challenge (
       challenge_id serial primary key,
       name text not null unique ,
       description text not null,
       slug text,
       difficulty int4 not null,
       blub text,
       polygon text not null,
       help text
);

create table osm_user (
       user_id serial primary key,
       osm_id text not null ,
       oauth_token text
);


create table task_state(
       state_id serial primary key,
       name text not null unique 
);

create table task (
       task_id serial primary key,
       challenge_id int4 not null,
       state_id int4,
       foreign key (task_id) references challenge(challenge_id),
       foreign key (state_id) references task_state(state_id)
);

select AddGeometryColumn('task','centroid',4326,'POINT',2);
create index task_centeroid_idx on task(centroid) using GIST;

create table task_assignment (
       task_assignment_id serial8 primary key,
       task_id int4 not null,
       user_id int4 not null,
       start_time timestamptz not null,
       end_time timestamptz ,
       action text,
       editor_used text,
       foreign key (task_id) references task(task_id),
       foreign key (user_id) references osm_user(user_id)
);
create index task_assignment_start_time_idx on task_assignment(start_time);
create index task_assignment_task_id on task_assignment(task_id);

create table task_object (
       task_object_id serial8 primary key,
       task_id int8 not null,
       geometry geometry not null,
       osm_id int8 ,
       osm_version int,
       osm_type text,
       object_role text,
       foreign key (task_id) references task(task_id)
       
);

commit;