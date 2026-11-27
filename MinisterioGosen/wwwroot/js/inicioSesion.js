$(function () {

// Despertar la API desde el servidor web
let activacion = null;

async function esperarAPI() {
    const limite = Date.now() + 120000;

    while (Date.now() < limite) {
        try {
            const response = await fetch("/Home/ActivarAPI", {
                method: "GET",
                cache: "no-store",
                signal: AbortSignal.timeout(15000)
            });

            if (response.ok) {
                const datos = await response.json();

                if (datos.disponible === true) {
                    console.log("API disponible");
                    return true;
                }
            }
        } catch (error) {
            console.warn("API todavía no disponible");
        }

        console.log("Reintentando conexión con la API...");

        await new Promise(resolve => setTimeout(resolve, 5000));
    }

    return false;
}

function activarAPI() {
    if (!activacion) {
        activacion = esperarAPI().then(disponible => {
            if (!disponible) {
                activacion = null;
            }

            return disponible;
        });
    }

    return activacion;
}

activarAPI();

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
            const boton = $(form).find("button[type='submit']");

            boton.prop("disabled", true);
            boton.text("Conectando con el servidor...");

            activarAPI().then(disponible => {
                if (disponible) {
                    form.submit();
                } else {
                    boton.prop("disabled", false);
                    boton.text("Iniciar Sesión");

                    alert("El servidor no está disponible. Intente nuevamente.");
                }
            });

            return false;
        }
    });

});