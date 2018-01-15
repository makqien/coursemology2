import 'brace/mode/python';
import 'brace/theme/github';

import React, { Component } from 'react';
import { Field, FieldArray } from 'redux-form';
import { defineMessages, FormattedMessage } from 'react-intl';
import { RadioButton } from 'material-ui/RadioButton';
import { Table, TableBody, TableHeader, TableHeaderColumn,
  TableRow, TableRowColumn } from 'material-ui/Table';
import { green50 } from 'material-ui/styles/colors';

// eslint-disable-next-line import/extensions, import/no-extraneous-dependencies, import/no-unresolved
import RichTextField from 'lib/components/redux-form/RichTextField';

import CheckboxFormGroup from '../components/CheckboxFormGroup';
import FileInput from '../components/FileInput';
import Editor from '../components/Editor';
import TestCaseView from '../containers/TestCaseView';
import ReadOnlyEditor from '../containers/ReadOnlyEditor';
import UploadedFileView from '../containers/UploadedFileView';
import ScribingView from '../containers/ScribingView';
import { parseLanguages } from '../utils';
import VoiceResponseAnswer from '../containers/VoiceResponseAnswer';

const translations = defineMessages({
  solutions: {
    id: 'course.assessment.submission.answer.solutions',
    defaultMessage: 'Solutions',
  },
  type: {
    id: 'course.assessment.submission.answer.type',
    defaultMessage: 'Type',
  },
  solution: {
    id: 'course.assessment.submission.answer.solution',
    defaultMessage: 'Solution',
  },
  grade: {
    id: 'course.assessment.submission.answer.grade',
    defaultMessage: 'Grade',
  },
  group: {
    id: 'course.assessment.submission.answer.group',
    defaultMessage: 'Group',
  },
  point: {
    id: 'course.assessment.submission.answer.point',
    defaultMessage: 'Point',
  },
  maximumGroupGrade: {
    id: 'course.assessment.submission.answer.maximumGroupGrade',
    defaultMessage: 'Maximum Grade for this Group',
  },
  pointGrade: {
    id: 'course.assessment.submission.answer.pointpGrade',
    defaultMessage: 'Grade for this Point',
  },
});

export default class Answers extends Component {
  static renderMultipleChoice(question, readOnly, answerId) {
    return (
      <Field
        name={`${answerId}[option_ids][0]`}
        component={Answers.renderMultipleChoiceOptions}
        {...{ question, answerId, readOnly }}
      />
    );
  }

  static renderMultipleChoiceOptions(props) {
    const { readOnly, question, input: { onChange, value } } = props;
    return (
      <div>
        {question.options.map(option => (
          <RadioButton
            key={option.id}
            value={option.id}
            onCheck={(event, buttonValue) => onChange(buttonValue)}
            checked={option.id === value}
            label={(
              <div
                style={option.correct && readOnly ? { backgroundColor: green50 } : null}
                dangerouslySetInnerHTML={{ __html: option.option.trim() }}
              />
            )}
            disabled={readOnly}
          />
        ))}
      </div>
    );
  }

  static renderMultipleResponse(question, readOnly, answerId) {
    return (
      <Field
        name={`${answerId}[option_ids]`}
        component={CheckboxFormGroup}
        options={question.options}
        {...{ readOnly }}
      />
    );
  }

  static renderFileUploader(question, readOnly, answerId) {
    return (
      <div>
        <FileInput name={`${answerId}[files]`} disabled={readOnly} />
      </div>
    );
  }

  static renderTextResponseSolutions(question) {
    /* eslint-disable react/no-array-index-key */
    return (
      <div>
        <hr />
        <h4><FormattedMessage {...translations.solutions} /></h4>
        <Table selectable={false}>
          <TableHeader adjustForCheckbox={false} displaySelectAll={false}>
            <TableRow>
              <TableHeaderColumn><FormattedMessage {...translations.type} /></TableHeaderColumn>
              <TableHeaderColumn><FormattedMessage {...translations.solution} /></TableHeaderColumn>
              <TableHeaderColumn><FormattedMessage {...translations.grade} /></TableHeaderColumn>
            </TableRow>
          </TableHeader>
          <TableBody displayRowCheckbox={false}>
            {question.solutions.map((solution, index) => (
              <TableRow key={index}>
                <TableRowColumn>{solution.solutionType}</TableRowColumn>
                <TableRowColumn style={{ whiteSpace: 'pre-wrap' }}>{solution.solution}</TableRowColumn>
                <TableRowColumn>{solution.grade}</TableRowColumn>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    );
    /* eslint-enable react/no-array-index-key */
  }

  static renderTextResponseComprehensionPoint(point) {
    /* eslint-disable react/no-array-index-key */
    return (
      <div>
        <br />
        <h6><FormattedMessage {...translations.point} /></h6>
        <Table selectable={false}>
          <TableBody displayRowCheckbox={false}>
            <TableRow>
              <TableRowColumn><FormattedMessage {...translations.pointGrade} /></TableRowColumn>
              <TableRowColumn>{point.pointGrade}</TableRowColumn>
            </TableRow>
            <TableRow>
              <TableHeaderColumn><FormattedMessage {...translations.type} /></TableHeaderColumn>
              <TableHeaderColumn><FormattedMessage {...translations.solution} /></TableHeaderColumn>
            </TableRow>
            {point.solutions.map((solution, index) => (
              <TableRow>
                <TableRowColumn>{solution.solutionType}</TableRowColumn>
                <TableRowColumn style={{ whiteSpace: 'pre-wrap' }}>{solution.solution}</TableRowColumn>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    );
    /* eslint-enable react/no-array-index-key */
  }

  static renderTextResponseComprehensionGroup(group) {
    /* eslint-disable react/no-array-index-key */
    return (
      <div>
        <br />
        <h5><FormattedMessage {...translations.group} /></h5>
        <Table selectable={false}>
          <TableBody displayRowCheckbox={false}>
            <TableRow>
              <TableRowColumn><FormattedMessage {...translations.maximumGroupGrade} /></TableRowColumn>
              <TableRowColumn>{group.maximumGroupGrade}</TableRowColumn>
            </TableRow>
            {group.points.map((point, index) => (
              <TableRow>
                <TableRowColumn colSpan={2}>
                  {Answers.renderTextResponseComprehensionPoint(point)}
                </TableRowColumn>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    );
    /* eslint-enable react/no-array-index-key */
  }

  static renderTextResponseComprehension(question) {
    /* eslint-disable react/no-array-index-key */
    return (
      <div>
        <hr />
        <h4><FormattedMessage {...translations.solutions} /></h4>
        {question.groups.map((group, index) => (
          Answers.renderTextResponseComprehensionGroup(group)
        ))}
      </div>
    );
    /* eslint-enable react/no-array-index-key */
  }

  static renderTextResponse(question, readOnly, answerId, graderView) {
    const allowUpload = question.allowAttachment;

    const readOnlyAnswer = (<Field
      name={`${answerId}[answer_text]`}
      component={props => (<div dangerouslySetInnerHTML={{ __html: props.input.value }} />)}
    />);

    const richtextAnswer = (<Field
      name={`${answerId}[answer_text]`}
      component={RichTextField}
      multiLine
    />);

    const plaintextAnswer = (<Field
      name={`${answerId}[answer_text]`}
      component="textarea"
      style={{ width: '100%' }}
      rows={5}
    />);

    const editableAnswer = question.autogradable ? plaintextAnswer : richtextAnswer;

    const solutionsTable = question.comprehension ?
                           (question.groups ? Answers.renderTextResponseComprehension(question) : null) :
                           (question.solutions ? Answers.renderTextResponseSolutions(question) : null);

    return (
      <div>
        { readOnly ? readOnlyAnswer : editableAnswer }
        { graderView ? solutionsTable : null }
        {allowUpload ? <UploadedFileView questionId={question.id} /> : null}
        {allowUpload && !readOnly ? Answers.renderFileUploader(question, readOnly, answerId) : null}
      </div>
    );
  }

  static renderFileUpload(question, readOnly, answerId) {
    return (
      <div>
        <UploadedFileView questionId={question.id} />
        {!readOnly ? Answers.renderFileUploader(question, readOnly, answerId) : null}
      </div>
    );
  }

  static renderProgrammingEditor(file, answerId, language) {
    return (
      <div key={file.filename}>
        <h5>{file.filename}</h5>
        <Editor
          name={`${answerId}[content]`}
          filename={file.filename}
          language={language}
        />
      </div>
    );
  }

  static renderReadOnlyProgrammingEditor(file, answerId) {
    const content = file.content.split('\n');
    return (
      <ReadOnlyEditor
        key={answerId}
        answerId={parseInt(answerId.split('[')[0], 10)}
        fileId={file.id}
        content={content}
      />
    );
  }

  static renderProgrammingFiles(props) {
    const { fields, readOnly, language } = props;
    return (
      <div>
        {fields.map((answerId, index) => {
          const file = fields.get(index);
          if (readOnly) {
            return Answers.renderReadOnlyProgrammingEditor(file, answerId);
          }
          return Answers.renderProgrammingEditor(file, answerId, language);
        })}
      </div>
    );
  }

  static renderProgramming(question, readOnly, answerId) {
    return (
      <div>
        <FieldArray
          name={`${answerId}[files_attributes]`}
          component={Answers.renderProgrammingFiles}
          {...{
            readOnly,
            language: parseLanguages(question.language),
          }}
        />
        <TestCaseView questionId={question.id} />
      </div>
    );
  }

  static renderVoiceResponse(question, readOnly, answerId) {
    return (
      <VoiceResponseAnswer
        question={question}
        readOnly={readOnly}
        answerId={answerId}
      />
    );
  }

  static renderScribing(scribing, readOnly, answerId) {
    return (
      <ScribingView scribing={scribing} readOnly={readOnly} answerId={answerId} />
    );
  }
}
