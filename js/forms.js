var __extends = this.__extends || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    __.prototype = b.prototype;
    d.prototype = new __();
};
var util = require('util');
var _ = require('underscore');

/**
* @namespace
*/
var widget;
(function (widget) {
    var Base = (function () {
        /**
        * @constructor
        * @param {String} name
        * @param {Object} options
        */
        function Base(name, options) {
            if (typeof options === "undefined") { options = {}; }
            this.type = "base";
            this.name = name;
            if (!('attributes' in options)) {
                options.attributes = {};
            }
            this.options = options;
        }
        Base.prototype.renderAttr = function (attr, value) {
            return util.format(" %s='%s' ", attr, value);
        };
        Base.prototype.renderAttributes = function (attrs) {
            var attr, result = "";
            for (attr in attrs) {
                result += this.renderAttr(attr, attrs[attr]);
            }
            return result;
        };

        /**
        * @return {Object}
        */
        Base.prototype.getDefaults = function () {
            return {
                value: this.data || this.options.attributes.value,
                name: this.name
            };
        };

        /**
        * @return {Object}
        */
        Base.prototype.toJSON = function () {
            return _.extend({}, this.options.attributes, this.getDefaults());
        };

        /**
        * @return {String}
        */
        Base.prototype.toHTML = function () {
            return util.format("<input name='%s' %s />", this.name, this.renderAttributes(this.toJSON()));
        };
        Base.prototype.toString = function () {
            return util.format("[object form.widget.%s]", this.type);
        };
        return Base;
    })();
    widget.Base = Base;

    var Text = (function (_super) {
        __extends(Text, _super);
        function Text() {
            _super.apply(this, arguments);
            this.type = "text";
        }
        Text.prototype.getDefaults = function () {
            return _.extend({}, _super.prototype.getDefaults.call(this), { type: this.type });
        };
        return Text;
    })(Base);
    widget.Text = Text;
    var Check = (function (_super) {
        __extends(Check, _super);
        function Check() {
            _super.apply(this, arguments);
            this.type = "check";
        }
        Check.fromData = function (data, value) {
            var check = new Check(_.isUndefined(data.key) ? data : data.key, { attributes: data.attributes });
            check.options.attributes.value = _.isUndefined(data.value) ? value : data.value;
            return check;
        };
        return Check;
    })(Text);
    widget.Check = Check;
    var Label = (function (_super) {
        __extends(Label, _super);
        function Label() {
            _super.apply(this, arguments);
            this.type = "label";
            this.defaults = {};
        }
        Label.prototype.getAttributes = function () {
            return _.extend({}, this.options.attributes, this.defaults);
        };
        Label.prototype.toHTML = function () {
            return util.format("<label %s >%s</label>", this.options.value || this.name, this.renderAttributes(this.getAttributes()));
        };
        return Label;
    })(Base);
    widget.Label = Label;
    var Radio = (function (_super) {
        __extends(Radio, _super);
        function Radio() {
            _super.apply(this, arguments);
            this.type = "radio";
        }
        Radio.fromData = function (option, value) {
            var _option;
            if (_.isObject(option)) {
                _option = new Radio(option.key, { attributes: option.attributes });
                _option.attributes.value = option.value;
            } else {
                _option = new Radio(option, { attributes: { value: value } });
            }
            return _option;
        };
        return Radio;
    })(Text);
    widget.Radio = Radio;
    var Button = (function (_super) {
        __extends(Button, _super);
        function Button() {
            _super.apply(this, arguments);
            this.type = "button";
        }
        return Button;
    })(Text);
    widget.Button = Button;
    var Submit = (function (_super) {
        __extends(Submit, _super);
        function Submit() {
            _super.apply(this, arguments);
            this.type = "submit";
        }
        return Submit;
    })(Button);
    widget.Submit = Submit;
    var Option = (function (_super) {
        __extends(Option, _super);
        function Option() {
            _super.apply(this, arguments);
            this.type = "option";
        }
        /**
        * @return {String}
        */
        Option.prototype.toHTML = function () {
            var data = this.toJSON();
            delete data.name;
            return util.format("<option %s >%s</option>", this.renderAttributes(this.toJSON()), _.escape(this.name));
        };
        Option.fromData = function (data, index) {
            var option;
            if (_.isObject(data)) {
                var attr = data.attributes || {};
                option = new Option(data.key, { attributes: attr });
                if (_.has(data, 'value')) {
                    option.data = data.value;
                }
            } else {
                option = new Option(data);
                if (index)
                    option.data = index;
            }
            return option;
        };
        return Option;
    })(Base);
    widget.Option = Option;
    var Select = (function (_super) {
        __extends(Select, _super);
        function Select() {
            _super.apply(this, arguments);
            this.type = "select";
        }
        /**
        * a HTML representation
        * @return {String}
        */
        Select.prototype.toHTML = function () {
            var _this = this;
            var html = "";
            if (this.options.multiple == true) {
                if (this.options.extended === true) {
                    html += this.options.options.map(function (o, i) {
                        var check = Check.fromData(o, i);
                        var label = new Label(o.key || o);
                        return check.toHTML() + label.toHTML();
                    }).join('\n');
                } else {
                    html += util.format("<select %s >\n", this.renderAttributes(_.extend({ multiple: true }, this.options.attributes)));
                    html += this.options.options.map(Option.fromData).map(function (option) {
                        return option.toHTML();
                    }).join("\n");
                    html += util.format("</select>\n");
                }
            } else {
                if (this.options.extended === true) {
                    html += this.options.options.map(function (option, index) {
                        var radio = Radio.fromData(option, index);
                        radio.options.attributes.name = _this.name;
                        var label = new widget.Label(option.key || option);
                        return radio.toHTML() + label.toHTML();
                    }).join('\n');
                } else {
                    html += util.format("<select %s >\n", this.renderAttributes(this.options.attributes));
                    html += this.options.options.map(Option.fromData).map(function (option) {
                        return option.toHTML();
                    }).join("\n");
                    html += util.format("</select>\n");
                }
            }

            return html;
        };

        /**
        * an JSON representation of the widget
        * @return {Object}
        */
        Select.prototype.toJSON = function () {
            var json = _super.prototype.toJSON.call(this);
            json.name = this.name;
            delete json.value;
            json.options = this.options.options.map(Option.fromData).map(function (option) {
                return option.toJSON();
            });
            return json;
        };
        return Select;
    })(Base);
    widget.Select = Select;
})(widget || (widget = {}));

var form;
(function (form) {
    var WidgetLoader = (function () {
        function WidgetLoader() {
        }
        WidgetLoader.prototype.getWidget = function (type, name, options) {
            switch (type) {
                case "choice":
                    return new widget.Select(name, options);
                case "button":
                    return new widget.Button(name, options);
                case "submit":
                    return new widget.Submit(name, options);
                default:
                    return new widget.Text(name, options);
            }
        };
        return WidgetLoader;
    })();
    form.WidgetLoader = WidgetLoader;
    var FormBuilder = (function () {
        function FormBuilder() {
            this.widgets = [];
            this.widgetLoaders = [];
            this.bound = false;
        }
        FormBuilder.prototype.addWidgetLoader = function (widgetLoader) {
            this.widgetLoaders.push(widgetLoader);
        };
        FormBuilder.prototype.resolveWidget = function (type, name, options) {
            var i = 0, widget;
            while (!widget || i < this.widgetLoaders.length) {
                widget = this.widgetLoaders[i].getWidget(type, name, options);
                i += 1;
            }
            return widget;
        };

        FormBuilder.prototype.add = function (type, name, options) {
            if (type instanceof widget.Base) {
                this.widgets.push(type);
            } else {
                this.resolveWidget(type, name, options);
            }
            return this;
        };
        FormBuilder.prototype.toHTML = function () {
            return this.widgets.map(function (w) {
                return w.toHTML();
            }).join("\n");
        };
        FormBuilder.prototype.toJSON = function () {
            return this.widgets.map(function (w) {
                return w.toJSON();
            });
        };
        FormBuilder.prototype.bindRequest = function () {
        };
        FormBuilder.prototype.setData = function () {
        };
        FormBuilder.prototype.getData = function () {
        };
        return FormBuilder;
    })();
    form.FormBuilder = FormBuilder;
    form.createFormBuilder = function () {
        var form = new FormBuilder();
        form.addWidgetLoader(new WidgetLoader());
        return form;
    };
})(form || (form = {}));

module.exports = {
    widget: widget,
    form: form
};
