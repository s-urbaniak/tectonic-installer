import _ from 'lodash';
import React from 'react';
import { connect } from 'react-redux';

import {
  AWS_CONTROLLERS,
  AWS_WORKERS,
  IAM_ROLE,
  IAM_ROLE_CREATE_OPTION,
  INSTANCE_TYPE,
  NUMBER_OF_INSTANCES,
  STORAGE_IOPS,
  STORAGE_SIZE_IN_GIB,
  STORAGE_TYPE,
} from '../cluster-config';

import { Form } from '../form';
import { toError, toAsyncError } from '../utils';
import { AWS_INSTANCE_TYPES } from '../facts';
import { NumberInput, Connect, Select } from './ui';
import { makeNodeForm, toKey } from './make-node-form';
import { Etcd } from './etcd';

const Row = ({label, htmlFor, children}) => <div className="row form-group">
  <div className="col-xs-4">
    <label htmlFor={htmlFor}>{label}</label>
  </div>
  <div className="col-xs-8">
    {children}
  </div>
</div>;

const IOPs = connect(
  ({clusterConfig}, {fieldName}) => ({type: clusterConfig[toKey(fieldName, STORAGE_TYPE)]})
)(
  ({type, fieldName}) => type !== 'io1' ? null : <Row htmlFor={`${fieldName}--storage-iops`} label="Storage Speed">
    <Connect field={toKey(fieldName, STORAGE_IOPS)}>
      <NumberInput id={`${fieldName}--storage-iops`} className="wiz-super-short-input" suffix="&nbsp;&nbsp;IOPS" />
    </Connect>
  </Row>
);

const IamRoles = connect(
  ({clusterConfig}) => ({roles: _.get(clusterConfig, ['extra', IAM_ROLE], [])})
)(
  ({roles, type}) => <Row htmlFor={`${type}--iam-role`} label="IAM Role">
    <Connect field={toKey(type, IAM_ROLE)}>
      <Select id={`${type}--iam-role`}>
        <option value={IAM_ROLE_CREATE_OPTION}>Create an IAM role for me (default)</option>
        {_.isArray(roles) && roles.map(r => <option value={r} key={r}>{r}</option>)}
      </Select>
    </Connect>
    {!_.isArray(roles) && <div className="wiz-error-message">Could not load IAM role list</div>}
  </Row>
);

const Errors = connect(
  ({clusterConfig}, {type}) => ({
    error: _.get(clusterConfig, toError(type)) || _.get(clusterConfig, toAsyncError(type)),
  })
)(props => props.error ? <div className="wiz-error-message">{props.error}</div> : <span />);

export const DefineNode = ({type, max, withIamRole = true}) => <div>
  {withIamRole && <IamRoles type={type} />}
  <Row htmlFor={`${type}--number`} label="Instances">
    <Connect field={toKey(type, NUMBER_OF_INSTANCES)}>
      <NumberInput className="wiz-super-short-input" id={`${type}--number`} min="1" max={max} />
    </Connect>
  </Row>
  <Row htmlFor={`${type}--instance`} label="Instance Type">
    <Connect field={toKey(type, INSTANCE_TYPE)}>
      <Select id={`${type}--instance`}>
        <option value="" disabled>Please select AWS EC2 instance type</option>
        {AWS_INSTANCE_TYPES.map(({value, label}) => <option value={value} key={value}>{label}</option>)}
      </Select>
    </Connect>
    {type === 'aws_etcds' && <p className="text-muted wiz-help-text">
      {/* eslint-disable react/jsx-no-target-blank */}
      Read the <a href="https://coreos.com/etcd/docs/latest/op-guide/hardware.html" rel="noopener" target="_blank">etcd recommended hardware</a> guide for best performance.
      {/* eslint-enable react/jsx-no-target-blank */}
    </p>}
  </Row>
  <Row htmlFor={`${type}--storage-size`} label="Storage Size">
    <Connect field={toKey(type, STORAGE_SIZE_IN_GIB)}>
      <NumberInput id={`${type}--storage-size`} className="wiz-super-short-input" suffix="&nbsp;&nbsp;GiB" />
    </Connect>
  </Row>
  <Row htmlFor={`${type}--storage-type`} label="Storage Type">
    <Connect field={toKey(type, STORAGE_TYPE)}>
      <Select id={`${type}--storage-type`}>
        <option value="" disabled>Please select storage type</option>
        <option value="gp2" key="gp2">General Purpose SSD (GP2)</option>
        <option value="io1" key="io1">Provisioned IOPS SSD (IO1)</option>
        <option value="standard" key="standard">Magnetic</option>
      </Select>
    </Connect>
  </Row>

  <IOPs fieldName={type} />

  <Errors type={type} />
</div>;

// TODO (kans): add ectdForm here
const fields = [
  makeNodeForm(AWS_CONTROLLERS),
  makeNodeForm(AWS_WORKERS),
];

const form = new Form('DefineNodesForm', fields);

export const AWS_DefineNodes = () => <div>
  <h3>Master Nodes</h3>
  <br />
  <DefineNode type={AWS_CONTROLLERS} max={10} />
  <hr />
  <h3>Worker Nodes</h3>
  <br />
  <DefineNode type={AWS_WORKERS} max={1000} />
  <form.Errors />
  <hr />
  <h3>etcd Nodes</h3>
  <br />
  <Etcd />
</div>;

AWS_DefineNodes.canNavigateForward = state => form.canNavigateForward(state) && Etcd.canNavigateForward(state);
