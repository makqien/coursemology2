$(document).ready(() => {
  function replaceBracketFromComprehensionAttributes() {
    if (document.getElementsByClassName('table-comprehension').length == 0)
      return; // do nothing if not comprehension question

    addFields = $('.table-comprehension a.add_fields');
    addFields.each((index) => {
      addFields[index].setAttribute(
        'data-association-insertion-node',
        replaceBracketWithUnderscore(addFields[index].getAttribute('data-association-insertion-node'))
      );
    });

    tbody = $('.table-comprehension tbody');
    tdSolution = $('.table-comprehension td.td-solution');
    aSolutionButton = $('.table-comprehension a.solution-button');
    tableElements = jQuery.merge(jQuery.merge(tbody, tdSolution), aSolutionButton);
    tableElements.each((index) => {
      tableElements[index].className = replaceBracketWithUnderscore(tableElements[index].className);
    });
  }

  function replaceBracketWithUnderscore(string) {
    return string.replace(/[\[\]']/g, '_');
  }

  function addSolutionField(event) {
    event.preventDefault();
    thisClassNameArr = this.className.split(' ');
    thisClassNameLast = thisClassNameArr[thisClassNameArr.length - 1];
    tdToFind = 'td.' + thisClassNameLast;
    $lastSolutionField = $(tdToFind + ' input:last-of-type').clone();
    $lastSolutionField.val("");
    $(tdToFind + ' div').append($lastSolutionField);
  };

  replaceBracketFromComprehensionAttributes();
  $('a.solution-button').on('click', addSolutionField);

  $('.table-comprehension').on('cocoon:after-insert', (e, node) => {
    replaceBracketFromComprehensionAttributes();
    node.find('td.td-solution-button a.solution-button').on('click', addSolutionField);
  });
});
