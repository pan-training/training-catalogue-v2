var SourceFilters = {
    lastId: function () {
        var existing_list_item_ids = $(".source-filter-form").map(function (i, c) { return $(c).data("id-in-filter-list") });
        if (existing_list_item_ids.length == 0) return 0;
        return Math.max.apply(null, existing_list_item_ids) + 1;
    },

    add: function () {
        var new_form = $($('#source-filter-template').clone().html().replace(/REPLACE_ME/g, SourceFilters.lastId()));
        new_form.appendTo('#source-filter-list');

        return false; // Stop form being submitted
    },

    addBlockFilter: function () {
        var new_form = $($('#source-filter-template').clone().html().replace(/REPLACE_ME/g, SourceFilters.lastId()).replace(/allow/, 'block'));
        new_form.appendTo('#source-block-list');

        return false; // Stop form being submitted
    },

    // Shows the value field belonging to the selected property. The other fields stay
    // disabled so that only one "value" parameter is submitted for this row.
    updateValueTypeForProperty: function (filterRow) {
        var targetValueType = filterRow.find('select[name$="[property]"] option:selected').data('value-type');

        filterRow.find('.source-filter-value').each(function () {
            var valueFieldGroup = $(this);
            var valueInput = valueFieldGroup.find(':input');
            var matchesTargetType = valueFieldGroup.data('value-type') === targetValueType;

            valueInput.prop('disabled', !matchesTargetType);
            valueFieldGroup.toggle(matchesTargetType);
        });
    },

    delete: function () {
        $(this).parents('.source-filter-form').fadeOut().find("input[name$='[_destroy]']").val("true");
    }
};

document.addEventListener("turbolinks:load", function () {
    $('#source-filters, #source-block-filters')
        .on('click', '#add-source-filter-btn, #add-source-filter-btn-label', SourceFilters.add)
        .on('click', '#add-source-block-filter-btn, #add-source-block-filter-btn-label', SourceFilters.addBlockFilter)
        .on('click', '.delete-source-filter-btn', SourceFilters.delete)
        .on('change', 'select[name$="[property]"]', function () {
            SourceFilters.updateValueTypeForProperty($(this).closest('.source-filter-form'));
        });
});
