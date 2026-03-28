import NoLayout from "#resources/layouts/no-layout.jsx"
import { Form } from "@inertiajs/react"

const Login = () => {
    return (
        <div className="hero bg-base-200 min-h-screen">
            <div className="hero-content flex-col lg:flex-row-reverse">
                <div className="text-center lg:text-left">
                    <h1 className="text-5xl font-bold">CMAK</h1>
                    <p className="py-6">
                        Texto configurable para la pantalla de inicio de sesión
                    </p>
                </div>
                <div className="card bg-base-100 w-full max-w-sm shrink-0 shadow-2xl">
                    <Form
                        className="card-body"
                        action={route("auth.login")}
                        method="post"
                        disableWhileProcessing={true}>
                        {({ errors, processing }) => (
                            <fieldset className="fieldset">
                                <label className="label">Email</label>
                                <input
                                    className="input"
                                    placeholder="Email"
                                    name="email"
                                    type="email"
                                />
                                <label className="label">Password</label>
                                <input
                                    type="password"
                                    className="input"
                                    name="password"
                                    placeholder="Password"
                                />
                                {Object.entries(errors).map(([key, value]) => (
                                    <p key={key} className="text-error">
                                        {value}
                                    </p>
                                ))}
                                <button className="btn btn-neutral mt-4">
                                    Login
                                </button>
                            </fieldset>
                        )}
                    </Form>
                </div>
            </div>
        </div>
    )
}

Login.layout = [NoLayout, {}]

export default Login
