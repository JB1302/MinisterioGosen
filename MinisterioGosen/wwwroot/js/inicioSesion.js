$(function () {

// Despertar la API desde el servidor web
fetch("/Home/ActivarAPI", {
    method: "GET",
    cache: "no-store"
})
.then(response => {
    if (!response.ok) {
        throw new Error("HTTP " + response.status);
    }

    console.log("API disponible");
})
.catch(error => {
    console.error("Error activando la API:", error);
});

    // Validaciones del inicio de sesión
    $("#InicioSesion").validate({
        rules: {
            Correo: {
                required: true,
                email: true
            },
            Contrasena: {
                required: true,
                minlength: 5
            }
        },
        messages: {
            Correo: {
                required: "Campo obligatorio",
                email: "Formato no válido"
            },
            Contrasena: {
                required: "Campo obligatorio",
                minlength: "Mínimo 5 caracteres"
            }
        },
        errorElement: "span",
        errorPlacement: function (error, element) {
            error.addClass("text-danger small d-block mt-1");
            element.closest(".form-floating").after(error);
        },
        highlight: function (element) {
            $(element).addClass("is-invalid");
            $(element).removeClass("is-valid");
        },
        unhighlight: function (element) {
            $(element).removeClass("is-invalid");
            $(element).addClass("is-valid");
        },
        submitHandler: function (form) {
            form.submit();
        }
    });

});