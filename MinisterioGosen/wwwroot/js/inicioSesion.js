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
                    signal: AbortSignal.timeout(
                        Math.min(90000, limite - Date.now())
                    )
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

            const restante = limite - Date.now();

            if (restante > 0) {
                await new Promise(resolve =>
                    setTimeout(resolve, Math.min(5000, restante))
                );
            }
        }

        return false;
    }

    function activarAPI() {
        if (!activacion) {
            activacion = esperarAPI().finally(() => {
                activacion = null;
            });
        }

        return activacion;
    }

    // Activar la API al cargar el login
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

            if (boton.prop("disabled")) {
                return false;
            }

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
            }).catch(error => {
                console.error("Error conectando con la API:", error);

                boton.prop("disabled", false);
                boton.text("Iniciar Sesión");

                alert("No fue posible conectar con el servidor.");
            });

            return false;
        }
    });

});