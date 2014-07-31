module.exports = (container)->
    container.set 'forms', container.share (c)->
        form = require 'mpm.form'
        _ = require 'lodash'
        forms = {}
        ###
            User SignUp
        ###
        forms.SignUp = (csrf)->
            form.create('sign_up')
            .add('username', "text",
                    {validators: form.validation.Required(), attributes: {class: 'form-control', required: true}})
            .add('email', "email",
                    {validators: form.validation.Email(), attributes: {class: 'form-control', required: true}})
            .add('password', "repeated", {attributes: {class: 'form-control', type: "password", required: true}})
            .add('_csrf', 'hidden',
                    {validators: form.validation.Required(), 'default': csrf, attributes: {id: "_csrf"}})
            .add('submit', 'submit', {'default': "Sign Up"})
        ###
            Login Form
        ###
        forms.Login = (csrf)->
            form.create('login')
            .add('email', 'text', {validators: [form.validation.Required(),
                                                form.validation.Email()], attributes: {class: 'form-control', required: true}})
            .add('password', 'password',
                    {validators: form.validation.Required(), attributes: {class: 'form-control', required: true}})
            .add('login', 'submit', {'default': "Login", attributes: {class: 'btn'}})
            .add('_csrf', 'hidden', {'default': csrf, attributes: {id: '_csrf'}})

        ###
            Video Form
        ###
        forms.VideoCreate = (categories = [])->
            categories = categories.map (category)->
                {key: category.title, value: category.id}
            form.create('video')
            .add('url', 'text',
                    {validators: form.validation.Required(), attributes: {'required', class: 'form-control'}})
            .add('category', 'select',
                    {choices: categories, validators: form.validation.Required(), attributes: {'required', class: 'form-control'}})

        forms.PlaylistFromUrl = (_categories = [])->
            _categories = _categories.map (category)->
                {key: category.title, value: category.id}
            _categories.unshift({key: 'choose a category'})
            form.create('playlist')
            .add('url', 'text', {validators: [form.validation.Required(),
                                              c.validation.PlaylistUrl(c.playlistParser)], attributes: {class: 'form-control'}})
            .add('category', 'select',
                    {choices: _categories, validators: form.validation.Required(), attributes: {'required', class: 'form-control'}})

        forms.Video = (categories = [])->
            _categories = categories.map (category)->
                {key: category.title, value: category.id}
            categoryTransform = {
                from: (c)->if c then c.id
                to: (id)->
                    categories.filter((c)->
                        c.id.toString() == id.toString())[0]
            }
            form.create('video')
            .add('title', 'text',
                    {validators: form.validation.Required(), attributes: {'required', class: 'form-control'}})
            .add('category', 'select',
                    {transform: categoryTransform, choices: _categories, validators: form.validation.Required(), attributes: {'required', class: 'form-control'}})
            .add('description', 'textarea', {attributes: {class: 'form-control', rows: 10}})

        ###
            Playlist form
        ###
        forms.Playlist = (_videos = [])->
            _videoTransform = {
                from: (videos)->
                    videos.map (v)->
                        v.id
                to: (ids)->
                    ids
            }
            form.create('playlist')
            .add('title', 'text',
                    {validators: form.validation.Required(), attributes: {required: true, class: 'form-control'}})
            .add('description', 'textarea',
                    {validators: form.validation.Required(), attributes: {rows: 3, required: true, class: 'form-control'}})
            .add('videos', 'select'
                    {choices:_videos.map((v)->{key:v.title,value:v.id}),transform: _videoTransform, validators: form.validation.Required(), attributes: {multiple:true,size:10,class: 'form-control'}})
            .add('help','label',{attributes:{value:'ctrl+click to select videos',class:'text-muted'}})
            .add('video_urls', 'textarea',
                    {label:'copy and paste videos urls',validators: form.validation.Required(), attributes: {class: 'form-control', rows: 10, required: true}})
            .add('help', 'label',
                    {default: 'Help Text', attributes: {class: 'help-block', value: 'Copy and paste multiple video urls in the videos field,separated by a space,comma or a line break.'}})

        return forms

